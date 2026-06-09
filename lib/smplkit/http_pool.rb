# frozen_string_literal: true

require "faraday/net_http_persistent"

module Smplkit
  # Keepalive connection pooling shared by every generated client.
  #
  # The openapi-generator Ruby/Faraday template builds each client's Faraday
  # connection with the default +net/http+ adapter. That adapter
  # (faraday-net_http) drives every request through the block form of
  # +Net::HTTP#start+, which opens the socket — including the TLS handshake
  # for https — runs a single request, then closes the socket on block exit.
  # A long-lived SDK client making many calls would therefore pay a fresh
  # DNS + TCP + TLS setup on *every* call, even though the
  # +Faraday::Connection+ object itself is memoized
  # (+@connection_regular ||= build_connection+).
  #
  # We swap in the +net_http_persistent+ adapter, which holds a keepalive
  # connection pool open and reuses sockets across requests. The generated
  # +ApiClient#build_connection+ runs +config.configure_connection(conn)+
  # *after* it sets the default adapter, and Faraday's builder lets +adapter+
  # be called again to replace the previous one — so registering a
  # +configure_faraday_connection+ block is enough to override the adapter
  # without editing generated code (which is overwritten on regeneration).
  # The memoized connection means the pool is built once per client and
  # reused for its lifetime.
  module HttpPool
    module_function

    # Register the keepalive-pooling adapter on a generated client
    # +Configuration+. Returns the configuration so callers can chain.
    def configure(configuration)
      configuration.configure_faraday_connection do |conn|
        conn.adapter :net_http_persistent
      end
      configuration
    end
  end
end
