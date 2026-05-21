# frozen_string_literal: true

module Smplkit
  module Management
    CONTEXT_REGISTRATION_LRU_SIZE = 10_000
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
    # declarations queued for the next attempt. +drain+ is unconditional and
    # used only by tests/teardown.
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

    # Thread-safe batch buffer for config declarations. Mirrors Python's
    # +_ConfigRegistrationBuffer+: per-config metadata is retained across
    # flushes so post-drain deltas re-attribute correctly, and items are
    # dedup'd per +(config_id, item_key)+ so an already-sent item is
    # never re-sent.
    class ConfigRegistrationBuffer
      def initialize
        @pending = {}    # config_id -> { id:, items: {}, ...meta }
        @meta = {}       # config_id -> { service:, environment:, parent:, name:, description: }
        @sent_items = {} # "#{config_id}::#{item_key}" -> true
        @lock = Mutex.new
      end

      # Idempotent — first writer's metadata wins.
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

      # Queue an item declaration for an already-declared config. Items
      # already sent in a previous +drain+ are skipped.
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

      # Returns and clears the pending batch; records sent items.
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
end
