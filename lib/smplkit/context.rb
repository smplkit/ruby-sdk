# frozen_string_literal: true

module Smplkit
  # Per-request context stash for context-sensitive evaluation (flags today,
  # likely more later).
  #
  # Backed by per-Fiber storage (Ruby 3.2+) which falls through to per-Thread
  # storage when not running under a Fiber scheduler. This gives proper
  # per-request isolation under both threaded and fiber-based concurrency.
  module RequestContext
    KEY = :smplkit_request_context

    module_function

    def get
      Thread.current[KEY] || []
    end

    def set(contexts)
      previous = Thread.current[KEY]
      Thread.current[KEY] = contexts.dup.freeze
      previous
    end

    def reset(previous)
      Thread.current[KEY] = previous
    end
  end

  # Returned by +Smplkit::Client#set_context+.
  #
  # Optional to use — bare +client.set_context([...])+ is fire-and-forget
  # (typical middleware pattern). Holding the return value or using the block
  # form auto-reverts to the prior context on exit, useful for scoped
  # overrides like impersonation.
  class ContextScope
    def initialize(previous)
      @previous = previous
      @exited = false
    end

    # Block form support: +client.set_context([...]) { ... }+.
    def call
      yield self
    ensure
      exit
    end

    # Restores the prior context. Idempotent — subsequent calls no-op.
    def exit
      return if @exited

      @exited = true
      RequestContext.reset(@previous)
    end
  end

  module_function

  def set_request_context(contexts)
    previous = RequestContext.set(contexts)
    ContextScope.new(previous)
  end

  def request_context
    RequestContext.get
  end
end
