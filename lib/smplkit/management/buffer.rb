# frozen_string_literal: true

module Smplkit
  module Management
    CONTEXT_REGISTRATION_LRU_SIZE = 10_000
    CONTEXT_BATCH_FLUSH_SIZE = 100
    FLAG_BATCH_FLUSH_SIZE = 50
    LOGGER_BATCH_FLUSH_SIZE = 50

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
