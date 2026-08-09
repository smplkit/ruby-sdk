# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::EventStream do
  subject(:stream) { described_class.new(app_base_url: "https://app.smplkit.test", api_key: "k") }

  # A task stand-in for the reactor task: +with_timeout+ runs the block
  # inline and +sleep+ records the requested delay without waiting.
  def fake_task(delays: [])
    task = double("AsyncTask")
    allow(task).to receive(:with_timeout) { |_seconds, &block| block.call }
    allow(task).to receive(:sleep) { |d| delays << d }
    task
  end

  # A response body stand-in that serves +chunks+ one +read+ at a time,
  # then EOF (nil).
  def fake_body(*chunks)
    remaining = chunks.dup
    body = double("ResponseBody")
    allow(body).to receive(:read) { remaining.shift }
    body
  end

  def fake_response(status: 200, content_type: "text/event-stream; charset=utf-8", body: fake_body)
    double("Response", status: status, headers: { "content-type" => content_type }, body: body, close: nil)
  end

  describe "#build_events_url" do
    it "appends the events path to an https base URL" do
      expect(stream.build_events_url).to eq("https://app.smplkit.test/api/v1/events")
    end

    it "preserves a plain http base URL and strips a trailing slash" do
      s2 = described_class.new(app_base_url: "http://localhost:8080/", api_key: "abc")
      expect(s2.build_events_url).to eq("http://localhost:8080/api/v1/events")
    end

    it "defaults to https when the scheme is missing" do
      s2 = described_class.new(app_base_url: "app.smplkit.test", api_key: "k")
      expect(s2.build_events_url).to eq("https://app.smplkit.test/api/v1/events")
    end

    it "keeps the api key out of the URL (auth travels as a Bearer header)" do
      expect(stream.build_events_url).not_to include("api_key")
      expect(stream.send(:request_headers)).to include(["authorization", "Bearer k"])
    end
  end

  describe "listener dispatch" do
    it "fires registered listeners for an event name" do
      seen = []
      stream.on("flag_changed") { |data| seen << data["id"] }
      stream.dispatch("flag_changed", "id" => "checkout-v2")
      expect(seen).to eq(["checkout-v2"])
    end

    it "swallows listener exceptions" do
      stream.on("x") { raise "boom" }
      expect { stream.dispatch("x", {}) }.not_to raise_error
    end

    it "off removes a listener" do
      cb = ->(_data) {}
      stream.on("x", &cb)
      stream.off("x", cb)
      seen = []
      stream.on("x") { |d| seen << d }
      stream.dispatch("x", "n" => 1)
      expect(seen).to eq(["n" => 1])
    end
  end

  describe "refetch callback registration" do
    it "on_reconnect registers a callback and returns it" do
      calls = 0
      cb = stream.on_reconnect { calls += 1 }
      stream.send(:run_refetch_callbacks)
      expect(calls).to eq(1)
      expect(cb).to be_a(Proc)
    end

    it "accepts a pre-built proc argument (identity-stable for off_reconnect)" do
      calls = 0
      cb = proc { calls += 1 }
      expect(stream.on_reconnect(cb)).to equal(cb)
      stream.send(:run_refetch_callbacks)
      expect(calls).to eq(1)
    end

    it "off_reconnect removes a callback by object identity" do
      calls = 0
      cb = stream.on_reconnect { calls += 1 }
      stream.off_reconnect(cb)
      stream.send(:run_refetch_callbacks)
      expect(calls).to eq(0)
    end

    it "swallows refetch callback exceptions and still runs the rest" do
      ran = false
      stream.on_reconnect { raise "boom" }
      stream.on_reconnect { ran = true }
      expect { stream.send(:run_refetch_callbacks) }.not_to raise_error
      expect(ran).to be(true)
    end
  end

  describe "#handle_event" do
    it "parses the JSON payload and dispatches it to listeners" do
      seen = []
      stream.on("flag_changed") { |data| seen << data["id"] }
      result = stream.handle_event("flag_changed", '{"id": "checkout-v2"}')
      expect(result).to eq(:dispatched)
      expect(seen).to eq(["checkout-v2"])
    end

    it "silently ignores event names with no listeners" do
      expect(stream.handle_event("brand_new_event", "{}")).to eq(:dispatched)
    end

    it "returns :unparseable for invalid JSON" do
      expect(stream.handle_event("flag_changed", "not json")).to eq(:unparseable)
    end

    it "returns :unparseable for JSON that is not an object" do
      expect(stream.handle_event("flag_changed", "[1, 2]")).to eq(:unparseable)
    end
  end

  describe "constants" do
    it "uses a 45 second liveness read timeout (two missed keepalives)" do
      expect(described_class::READ_TIMEOUT).to eq(45)
    end

    it "caps the reconnect backoff at 60 seconds" do
      expect(described_class::MAX_BACKOFF).to eq(60)
    end

    it "defaults the backoff base to 1 second until the server sends retry:" do
      expect(described_class::DEFAULT_RETRY).to eq(1.0)
    end

    it "USER_AGENT identifies the Ruby SDK with the gem version" do
      expect(described_class::USER_AGENT).to eq("smplkit-sdk-ruby/#{Smplkit.gem_version}")
      expect(described_class::USER_AGENT).to start_with("smplkit-sdk-ruby/")
    end
  end

  describe "lifecycle without a server" do
    # WebMock intercepts async-http; a 401 keeps the background thread on the
    # normal handled-error path (ConnectionError -> backoff) instead of dying
    # on WebMock's Exception-level unstubbed-request error.
    before { stub_request(:get, "https://app.smplkit.test/api/v1/events").to_return(status: 401) }

    it "start spawns a daemon thread and stop tears it down" do
      stream.start
      expect(stream.instance_variable_get(:@stream_thread)).to be_a(Thread)
      stream.stop
      expect(stream.instance_variable_get(:@stream_thread)).to be_nil
      expect(stream.connection_status).to eq("disconnected")
    end

    it "start is idempotent on repeat calls" do
      stream.start
      original = stream.instance_variable_get(:@stream_thread)
      stream.start
      expect(stream.instance_variable_get(:@stream_thread)).to equal(original)
      stream.stop
    end
  end

  describe "#connect_and_stream" do
    let(:endpoint) { double("Endpoint", path: "/api/v1/events") }
    let(:http_client) { double("HTTPClient", close: nil) }
    let(:task) { fake_task }

    before do
      allow(Async::HTTP::Endpoint).to receive(:parse).and_return(endpoint)
      allow(Async::HTTP::Client).to receive(:new).and_return(http_client)
    end

    it "marks the stream connected on HTTP 200 with a text/event-stream content type" do
      response = fake_response
      allow(http_client).to receive(:get).and_return(response)
      statuses = []
      allow(stream).to receive(:read_loop) { statuses << stream.connection_status }
      stream.send(:connect_and_stream, task)
      expect(statuses).to eq(["connected"])
    end

    it "sends Accept, Bearer Authorization, and User-Agent headers" do
      response = fake_response
      captured = nil
      allow(http_client).to receive(:get) do |_path, headers|
        captured = headers
        response
      end
      stream.send(:connect_and_stream, task)
      expect(captured).to contain_exactly(
        ["accept", "text/event-stream"],
        ["authorization", "Bearer k"],
        ["user-agent", "smplkit-sdk-ruby/#{Smplkit.gem_version}"]
      )
    end

    it "reads the body through the SSE parser and dispatches events to listeners" do
      body = fake_body("event: flag_changed\n", "data: {\"id\": \"x\"}\n\n")
      response = fake_response(body: body)
      allow(http_client).to receive(:get).and_return(response)
      seen = []
      stream.on("flag_changed") { |data| seen << data["id"] }
      stream.send(:connect_and_stream, task)
      expect(seen).to eq(["x"])
    end

    it "raises ConnectionError on a non-200 response (e.g. 401 bad auth)" do
      response = fake_response(status: 401, content_type: "application/json")
      allow(http_client).to receive(:get).and_return(response)
      expect { stream.send(:connect_and_stream, task) }
        .to raise_error(Smplkit::ConnectionError, /HTTP 401/)
      expect(stream.connection_status).not_to eq("connected")
    end

    it "raises ConnectionError on a 200 without a text/event-stream content type" do
      response = fake_response(content_type: "text/html")
      allow(http_client).to receive(:get).and_return(response)
      expect { stream.send(:connect_and_stream, task) }
        .to raise_error(Smplkit::ConnectionError, %r{content-type: "text/html"})
    end

    it "records the platform.event_connections gauge up on connect and down on disconnect" do
      metrics = double("metrics", record_gauge: nil)
      stream.instance_variable_set(:@metrics, metrics)
      response = fake_response
      allow(http_client).to receive(:get).and_return(response)
      stream.send(:connect_and_stream, task)
      expect(metrics).to have_received(:record_gauge)
        .with("platform.event_connections", 1, unit: "connections").ordered
      expect(metrics).to have_received(:record_gauge)
        .with("platform.event_connections", 0, unit: "connections").ordered
    end

    it "does not record a disconnect gauge when the handshake never completed" do
      metrics = double("metrics", record_gauge: nil)
      stream.instance_variable_set(:@metrics, metrics)
      response = fake_response(status: 500)
      allow(http_client).to receive(:get).and_return(response)
      expect { stream.send(:connect_and_stream, task) }.to raise_error(Smplkit::ConnectionError)
      expect(metrics).not_to have_received(:record_gauge)
    end

    it "always closes the response and client and clears the connection refs" do
      response = fake_response
      allow(http_client).to receive(:get).and_return(response)
      stream.send(:connect_and_stream, task)
      expect(response).to have_received(:close)
      expect(http_client).to have_received(:close)
      expect(stream.instance_variable_get(:@response)).to be_nil
      expect(stream.instance_variable_get(:@client)).to be_nil
    end

    it "tears down the client even when the GET itself raises" do
      allow(http_client).to receive(:get).and_raise(IOError, "broken pipe")
      expect { stream.send(:connect_and_stream, task) }.to raise_error(IOError)
      expect(http_client).to have_received(:close)
    end
  end

  describe "#read_loop" do
    it "returns immediately once the stream has been closed" do
      stream.instance_variable_set(:@closed, true)
      body = double("ResponseBody", read: nil)
      stream.send(:read_loop, fake_task, body)
      expect(body).not_to have_received(:read)
    end

    it "seeds the backoff base from the server's retry: field" do
      body = fake_body("retry: 500\n\nevent: connected\ndata: {}\n\n")
      stream.send(:read_loop, fake_task, body)
      expect(stream.instance_variable_get(:@retry_base)).to eq(0.5)
    end

    it "raises a liveness timeout once the 45s deadline passes with no data" do
      body = double("ResponseBody")
      task = double("AsyncTask")
      allow(task).to receive(:with_timeout)
        .with(Smplkit::EventStream::POLL_INTERVAL).and_raise(Async::TimeoutError)
      # First poll: 10s elapsed — under the deadline, keep waiting.
      # Second poll: 46s elapsed — deadline breached, raise to reconnect.
      allow(stream).to receive(:monotonic_now).and_return(0.0, 10.0, 46.0)
      expect { stream.send(:read_loop, task, body) }.to raise_error(
        Async::TimeoutError, /no data for 45s/
      )
    end

    it "keeps polling through idle reads while the liveness deadline holds" do
      body = double("ResponseBody")
      task = double("AsyncTask")
      polls = 0
      allow(task).to receive(:with_timeout) do
        polls += 1
        stream.instance_variable_set(:@closed, true) if polls == 3
        raise Async::TimeoutError
      end
      allow(stream).to receive(:monotonic_now).and_return(0.0, 1.0, 2.0, 3.0)
      # Never breaches the deadline; exits promptly when stop flips @closed.
      stream.send(:read_loop, task, body)
      expect(polls).to eq(3)
    end

    it "parks each read for at most the poll interval so stop is honored promptly" do
      timeouts = []
      task = double("AsyncTask")
      allow(task).to receive(:with_timeout) do |seconds, &block|
        timeouts << seconds
        block.call
      end
      stream.send(:read_loop, task, fake_body(": keepalive\n\n", ": keepalive\n\n"))
      expect(timeouts).to eq([1.0, 1.0, 1.0])
    end

    it "pushes the liveness deadline out on every received chunk" do
      body = double("ResponseBody")
      task = double("AsyncTask")
      reads = 0
      allow(task).to receive(:with_timeout) do |_seconds, &block|
        reads += 1
        raise Async::TimeoutError if reads.odd? # idle poll between chunks

        block.call
      end
      chunks = [": keepalive\n\n", ": keepalive\n\n", nil]
      allow(body).to receive(:read) { chunks.shift }
      # Clock advances 40s per step: any single gap is under 45s only
      # because each chunk resets the deadline; without the reset the
      # third poll would breach it.
      clock = -40.0
      allow(stream).to receive(:monotonic_now) { clock += 40.0 }
      expect { stream.send(:read_loop, task, body) }.not_to raise_error
    end
  end

  describe "#stream_main (reconnect backoff)" do
    it "resets the backoff to the base delay after a successful connect" do
      delays = []
      task = fake_task(delays: delays)
      calls = 0
      allow(stream).to receive(:connect_and_stream) do
        calls += 1
        case calls
        when 1, 2, 3, 5
          raise "connect failed"
        when 4
          stream.send(:mark_connected) # successful connect (200 + SSE) ...
          raise "stream dropped"       # ... that later drops
        else
          stream.instance_variable_set(:@closed, true)
        end
      end
      stream.send(:stream_main, task)
      expect(delays).to eq([1.0, 2.0, 4.0, 1.0, 2.0])
    end

    it "runs registered refetch callbacks on reconnect but not on the initial connect" do
      refetches = 0
      refetches_at_initial_connect = nil
      stream.on_reconnect { refetches += 1 }
      task = fake_task
      calls = 0
      allow(stream).to receive(:connect_and_stream) do
        calls += 1
        stream.send(:mark_connected)
        if calls == 1
          refetches_at_initial_connect = refetches
          raise "stream dropped"
        else
          stream.instance_variable_set(:@closed, true)
        end
      end
      stream.send(:stream_main, task)
      expect(refetches_at_initial_connect).to eq(0)
      expect(refetches).to eq(1)
    end

    it "caps the backoff delay at MAX_BACKOFF" do
      delays = []
      task = fake_task(delays: delays)
      calls = 0
      allow(stream).to receive(:connect_and_stream) do
        calls += 1
        stream.instance_variable_set(:@closed, true) if calls == 9
        raise "connect failed"
      end
      stream.send(:stream_main, task)
      expect(delays).to eq([1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 60, 60])
    end

    it "uses a server-provided retry value as the backoff base" do
      stream.instance_variable_set(:@retry_base, 0.5)
      delays = []
      task = fake_task(delays: delays)
      calls = 0
      allow(stream).to receive(:connect_and_stream) do
        calls += 1
        stream.instance_variable_set(:@closed, true) if calls == 3
        raise "connect failed"
      end
      stream.send(:stream_main, task)
      expect(delays).to eq([0.5, 1.0])
    end

    it "returns without connecting when already closed" do
      stream.instance_variable_set(:@closed, true)
      allow(stream).to receive(:connect_and_stream)
      stream.send(:stream_main, fake_task)
      expect(stream).not_to have_received(:connect_and_stream)
    end

    it "returns without sleeping when closed while the stream was erroring" do
      task = fake_task
      allow(stream).to receive(:connect_and_stream) do
        stream.instance_variable_set(:@closed, true)
        raise "torn down by stop"
      end
      stream.send(:stream_main, task)
      expect(task).not_to have_received(:sleep)
    end

    it "returns without sleeping when closed right after a clean stream end" do
      task = fake_task
      allow(stream).to receive(:connect_and_stream) do
        stream.instance_variable_set(:@closed, true)
      end
      stream.send(:stream_main, task)
      expect(task).not_to have_received(:sleep)
    end
  end

  describe "#stop with an active connection" do
    it "leaves the reactor's connection alone when its thread exits on its own" do
      # The reactor closes its own response/client in-reactor on the way
      # out; a cross-thread close from stop would race it (and cannot
      # wake a blocked read — the hang this design exists to prevent).
      response = double("Response", close: nil)
      client = double("HTTPClient", close: nil)
      stream.instance_variable_set(:@response, response)
      stream.instance_variable_set(:@client, client)
      thread = Thread.new { sleep(0.01) }
      stream.instance_variable_set(:@stream_thread, thread)
      stream.stop
      expect(response).not_to have_received(:close)
      expect(client).not_to have_received(:close)
      expect(stream.connection_status).to eq("disconnected")
    end

    it "kills a wedged thread and closes the connection as a last resort" do
      response = double("Response", close: nil)
      client = double("HTTPClient", close: nil)
      stream.instance_variable_set(:@response, response)
      stream.instance_variable_set(:@client, client)
      thread = double("Thread")
      allow(thread).to receive(:join)
      allow(thread).to receive(:alive?).and_return(true)
      allow(thread).to receive(:kill)
      stream.instance_variable_set(:@stream_thread, thread)
      stream.stop
      expect(thread).to have_received(:kill)
      expect(response).to have_received(:close)
      expect(client).to have_received(:close)
      expect(stream.connection_status).to eq("disconnected")
    end

    it "swallows exceptions raised by the last-resort close" do
      bad = double("Response")
      allow(bad).to receive(:close).and_raise("boom")
      stream.instance_variable_set(:@response, bad)
      thread = double("Thread", join: nil, alive?: true, kill: nil)
      stream.instance_variable_set(:@stream_thread, thread)
      expect { stream.stop }.not_to raise_error
    end
  end

  describe "#run_reactor" do
    it "wraps Sync exceptions in a debug log instead of bubbling" do
      allow(stream).to receive(:stream_main).and_raise("boom")
      Smplkit::Debug.enabled = true
      expect { stream.send(:run_reactor) }.to output(/exited unexpectedly/).to_stderr
    ensure
      Smplkit::Debug.enabled = false
    end
  end
end

RSpec.describe Smplkit::EventStream::Parser do
  subject(:parser) { described_class.new }

  def events_for(*chunks)
    chunks.flat_map { |chunk| parser.feed(chunk) }
  end

  def names_and_data(events)
    events.map { |e| [e.name, e.data] }
  end

  it "parses a complete event with LF terminators" do
    events = events_for("event: flag_changed\ndata: {\"id\": \"x\"}\n\n")
    expect(names_and_data(events)).to eq([["flag_changed", '{"id": "x"}']])
  end

  it "parses CRLF terminators" do
    events = events_for("event: flag_changed\r\ndata: {}\r\n\r\n")
    expect(names_and_data(events)).to eq([["flag_changed", "{}"]])
  end

  it "parses bare CR terminators" do
    events = events_for("event: flag_changed\rdata: {}\r\r", "\n")
    expect(names_and_data(events)).to eq([["flag_changed", "{}"]])
  end

  it "handles a CRLF split across two chunks without emitting a phantom blank line" do
    events = events_for("event: flag_changed\r", "\ndata: {}\r\n", "\r\n")
    expect(names_and_data(events)).to eq([["flag_changed", "{}"]])
  end

  it "handles a field value split across read-buffer boundaries" do
    events = events_for("event: flag_ch", "anged\ndat", "a: {\"id\": \"che", "ckout\"}\n\n")
    expect(names_and_data(events)).to eq([["flag_changed", '{"id": "checkout"}']])
  end

  it "handles a multi-byte UTF-8 character split across chunks" do
    bytes = "data: {\"id\": \"café\"}\n\n".dup.force_encoding(Encoding::BINARY)
    events = events_for(bytes.byteslice(0, 18), bytes.byteslice(18..))
    expect(events.first.data).to eq("{\"id\": \"café\"}")
    expect(events.first.data.valid_encoding?).to be(true)
  end

  it "joins multiple data lines with a newline" do
    events = events_for("data: line one\ndata: line two\n\n")
    expect(events.first.data).to eq("line one\nline two")
  end

  it "ignores comment lines (the server keepalive) without disturbing a pending event" do
    events = events_for("event: flag_changed\n: keepalive\ndata: {}\n\n")
    expect(names_and_data(events)).to eq([["flag_changed", "{}"]])
  end

  it "emits nothing for a comment-only frame" do
    expect(events_for(": keepalive\n\n")).to eq([])
  end

  it "ignores unknown fields (including id — the SDK never resumes)" do
    events = events_for("id: 42\nfancy: field\nevent: flag_changed\ndata: {}\n\n")
    expect(names_and_data(events)).to eq([["flag_changed", "{}"]])
  end

  it "treats a line with no colon as a field name with an empty value" do
    events = events_for("data\ndata: x\n\n")
    expect(events.first.data).to eq("\nx")
  end

  it "strips exactly one leading space from a field value" do
    events = events_for("data:no-space\ndata:  two-spaces\n\n")
    expect(events.first.data).to eq("no-space\n two-spaces")
  end

  it "defaults the event name to message when no event field is present" do
    events = events_for("data: {}\n\n")
    expect(events.first.name).to eq("message")
  end

  it "discards an event with no data but still resets the event type" do
    events = events_for("event: flag_changed\n\ndata: {}\n\n")
    expect(names_and_data(events)).to eq([["message", "{}"]])
  end

  it "resets state between events" do
    events = events_for("event: a\ndata: 1\n\nevent: b\ndata: 2\n\n")
    expect(names_and_data(events)).to eq([%w[a 1], %w[b 2]])
  end

  it "strips a leading UTF-8 BOM" do
    events = events_for("\xEF\xBB\xBFdata: {}\n\n")
    expect(names_and_data(events)).to eq([["message", "{}"]])
  end

  it "strips a BOM split across chunks" do
    events = events_for("\xEF", "\xBB", "\xBFdata: {}\n\n")
    expect(names_and_data(events)).to eq([["message", "{}"]])
  end

  it "stops waiting for a BOM once the first bytes cannot be one" do
    events = events_for("d", "ata: {}\n\n")
    expect(names_and_data(events)).to eq([["message", "{}"]])
  end

  it "only strips the BOM at the very start of the stream" do
    events = events_for("data: x\n\ndata: \xEF\xBB\xBFy\n\n")
    expect(events.last.data.bytes.first(3)).to eq([0xEF, 0xBB, 0xBF])
  end

  it "records the retry field in milliseconds" do
    parser.feed("retry: 1500\n")
    expect(parser.retry_ms).to eq(1500)
  end

  it "ignores a non-numeric retry value" do
    parser.feed("retry: soon\n")
    expect(parser.retry_ms).to be_nil
  end

  it "returns no events while a frame is incomplete" do
    expect(parser.feed("event: flag_changed\ndata: {}")).to eq([])
  end
end
