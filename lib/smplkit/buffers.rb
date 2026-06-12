# frozen_string_literal: true

require "set"

# Registration buffers backing the SDK's batched-discovery sub-clients.
#
# Four buffer types, each owned by the sub-client that drains it:
#
# - +ContextRegistrationBuffer+  ->  +client.platform.contexts._buffer+
# - +FlagRegistrationBuffer+     ->  +client.flags._buffer+
# - +ConfigRegistrationBuffer+   ->  +client.config._buffer+
# - +LoggerRegistrationBuffer+   ->  +client.logging.loggers._buffer+
#
# There is exactly one buffer + one bulk-flush implementation per resource.
module Smplkit
  # When the deduplication LRU exceeds this size, the oldest entry is
  # evicted. The next observation of an evicted entry will re-flush.
  CONTEXT_REGISTRATION_LRU_SIZE = 10_000

  # Pending-queue size that triggers an immediate background flush from
  # inside +register+.  The periodic timer on +Client+ covers the tail
  # case for low-traffic services.
  CONTEXT_BATCH_FLUSH_SIZE = 100
  FLAG_BATCH_FLUSH_SIZE = 50
  LOGGER_BATCH_FLUSH_SIZE = 50
  CONFIG_BATCH_FLUSH_SIZE = 50

  # Thread-safe batch buffer for context registration.
  class ContextRegistrationBuffer
    def initialize
      @seen = {}
      @pending = []
      @lock = Mutex.new
    end

    # Queue any unseen contexts.
    def observe(contexts)
      @lock.synchronize do
        contexts.each do |ctx|
          cache_key = [ctx.type, ctx.key]
          next if @seen.key?(cache_key)

          @seen.shift if @seen.size >= CONTEXT_REGISTRATION_LRU_SIZE
          @seen[cache_key] = ctx.attributes
          @pending << { "type" => ctx.type, "key" => ctx.key, "attributes" => ctx.attributes.dup }
        end
      end
    end

    # Return and clear the current pending batch.
    def drain
      @lock.synchronize do
        batch = @pending
        @pending = []
        batch
      end
    end

    def pending_count
      @lock.synchronize { @pending.length }
    end
  end

  # Thread-safe batch buffer for flag declarations.
  #
  # Use +peek+ + +commit(ids)+ for the send path so a failed POST leaves
  # declarations queued for the next attempt; the legacy +drain+ is
  # unconditional and used only by tests.
  class FlagRegistrationBuffer
    def initialize
      @seen = {}
      @pending = []
      @lock = Mutex.new
    end

    def add(declaration)
      @lock.synchronize do
        next if @seen.key?(declaration.id)

        @seen[declaration.id] = true
        item = { "id" => declaration.id, "type" => declaration.type, "default" => declaration.default }
        item["service"] = declaration.service if declaration.service
        item["environment"] = declaration.environment if declaration.environment
        @pending << item
      end
    end

    def peek
      @lock.synchronize { @pending.dup }
    end

    def commit(ids)
      return if ids.nil? || ids.empty?

      committed = ids.to_set
      @lock.synchronize { @pending.reject! { |item| committed.include?(item["id"]) } }
    end

    def drain
      @lock.synchronize do
        batch = @pending
        @pending = []
        batch
      end
    end

    def pending_count
      @lock.synchronize { @pending.length }
    end
  end

  # Thread-safe batch buffer for config declarations.
  #
  # Configs differ from flags/loggers because each entry carries a nested
  # +items+ dict that grows incrementally as the customer's code touches more
  # typed getters on a declared handle. The buffer therefore stores per-config
  # metadata permanently (so post-flush deltas can be re-attributed to the
  # right service/environment) and dedups items per +(config_id, item_key)+ so
  # we never re-send an item that the server has already accepted.
  #
  # Call sites:
  #
  # - +declare+ once per +client.config.bind(id, ...)+.
  # - +add_item+ for every introspected leaf field, or anything else the
  #   runtime client observes. Repeated calls with the same
  #   +(config_id, item_key)+ after a successful flush are no-ops.
  # - +drain+ returns the pending payload list, clears the pending buffer, and
  #   records what was sent.
  #
  # The buffer never drops metadata — only +pending+ is cleared on flush. If
  # the customer's code declares new items via typed getters after a flush, a
  # fresh pending entry is created using the stored metadata so the server can
  # route the delta to the right source row.
  class ConfigRegistrationBuffer
    def initialize
      @pending = {}    # config_id -> { id:, items: {}, ...meta }
      @meta = {}       # config_id -> { service:, environment:, parent:, name:, description: }
      @sent_items = {} # "#{config_id}::#{item_key}" -> true
      @lock = Mutex.new
    end

    # Register a configuration. Idempotent within a process.
    def declare(config_id, service:, environment:, parent: nil, name: nil, description: nil)
      @lock.synchronize do
        next if @meta.key?(config_id)

        @meta[config_id] = {
          service: service, environment: environment,
          parent: parent, name: name, description: description
        }
        @pending[config_id] = build_entry(config_id)
      end
    end

    # Queue an item declaration if not already sent.
    #
    # Must be preceded by +declare+ for the same +config_id+; otherwise the
    # call is dropped (no implicit declaration).
    def add_item(config_id, item_key, item_type, default, description = nil)
      @lock.synchronize do
        next unless @meta.key?(config_id)
        next if @sent_items.key?("#{config_id}::#{item_key}")

        entry = (@pending[config_id] ||= build_entry(config_id))
        next if entry["items"].key?(item_key)

        item = { "value" => default, "type" => item_type }
        item["description"] = description unless description.nil?
        entry["items"][item_key] = item
      end
    end

    # Return and clear the pending batch; record sent items.
    def drain
      @lock.synchronize do
        entries = @pending.values
        entries.each do |entry|
          entry["items"].each_key { |item_key| @sent_items["#{entry["id"]}::#{item_key}"] = true }
        end
        @pending = {}
        entries
      end
    end

    def pending_count
      @lock.synchronize { @pending.size }
    end

    private

    def build_entry(config_id)
      meta = @meta[config_id]
      entry = { "id" => config_id, "items" => {} }
      %i[service environment parent name description].each do |k|
        v = meta[k]
        entry[k.to_s] = v unless v.nil?
      end
      entry
    end
  end

  # Thread-safe batch buffer for logger discovery.
  class LoggerRegistrationBuffer
    def initialize
      @seen = {}
      @pending = []
      @lock = Mutex.new
    end

    def add(source)
      @lock.synchronize do
        next if @seen.key?(source.name)

        @seen[source.name] = source.resolved_level
        item = { "id" => source.name, "resolved_level" => source.resolved_level&.to_s }
        item["level"] = source.level&.to_s if source.level
        item["service"] = source.service if source.service
        item["environment"] = source.environment if source.environment
        @pending << item
      end
    end

    def drain
      @lock.synchronize do
        batch = @pending
        @pending = []
        batch
      end
    end

    def pending_count
      @lock.synchronize { @pending.length }
    end
  end
end
