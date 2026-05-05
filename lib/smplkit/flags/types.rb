# frozen_string_literal: true

module Smplkit
  # Operators supported by +Smplkit::Rule#when+.
  #
  # Customers should prefer +Smplkit::Op::EQ+ etc. over raw strings so the IDE
  # can validate calls. Raw strings are still accepted for backward
  # compatibility.
  module Op
    EQ = "=="
    NEQ = "!="
    LT = "<"
    LTE = "<="
    GT = ">"
    GTE = ">="
    IN = "in"
    CONTAINS = "contains"

    ALL = [EQ, NEQ, LT, LTE, GT, GTE, IN, CONTAINS].freeze
  end

  # A typed entity referenced by targeting rules and registered with smplkit.
  #
  # Represents a single entity (user, account, device, etc.). The +type+ and
  # +key+ identify the entity; +attributes+ (provided as a hash and/or keyword
  # arguments) carry the data that targeting rules evaluate against.
  #
  # Used for both authoring (+flag.get(context: [...])+,
  # +client.set_context([...])+, +mgmt.contexts.register([...])+) and reading
  # (+mgmt.contexts.list/get+ return populated +Context+ instances with
  # +save+ / +delete+ ready to call).
  #
  # Examples:
  #
  #   Smplkit::Context.new("user", "user-123", plan: "enterprise")
  #   Smplkit::Context.new("account", "acme-corp", { "region" => "us" }, employee_count: 500)
  class Context
    CONTEXT_FIELDS = %i[type key name attributes created_at updated_at].freeze

    attr_reader :type, :key, :attributes
    attr_accessor :name, :created_at, :updated_at

    def initialize(type, key, attributes = nil, name: nil, created_at: nil, updated_at: nil, **kwargs)
      raise TypeError, "Context type must be a String, got #{type.class}: #{type.inspect}" unless type.is_a?(String)
      unless key.is_a?(String)
        raise TypeError,
              "Context key must be a String, got #{key.class}: #{key.inspect}. " \
              "If your identifier is numeric, stringify it at the SDK boundary."
      end

      @type = type
      @key = key
      @name = name
      @attributes = stringify_keys(merge_attributes(attributes, kwargs))
      @created_at = created_at
      @updated_at = updated_at
      @client = nil
    end

    # Composite "{type}:{key}" identifier.
    def id
      "#{@type}:#{@key}"
    end

    # Bulk-replace attributes. Forces String keys to match the wire format.
    def attributes=(new_attrs)
      @attributes = stringify_keys(new_attrs || {})
    end

    # Internal: associate a management client with this context so save/delete
    # can route through it.
    def _bind_client(client)
      @client = client
      self
    end

    def _client
      @client
    end

    # Persist this context to the server (create or update).
    def save
      raise "Context was constructed without a client; cannot save" if @client.nil?

      updated = @client._save_context(self)
      _apply(updated)
      self
    end
    alias save! save

    # Delete this context from the server.
    def delete
      raise "Context was constructed without a client; cannot delete" if @client.nil?

      @client.delete(id)
    end
    alias delete! delete

    def to_eval_hash
      { "key" => @key, **@attributes }
    end

    def ==(other)
      other.is_a?(Context) && other.type == @type && other.key == @key && other.attributes == @attributes
    end

    def hash
      [@type, @key, @attributes].hash
    end

    def eql?(other)
      self == other
    end

    def inspect
      "#<Smplkit::Context type=#{@type.inspect} key=#{@key.inspect} " \
        "name=#{@name.inspect} attributes=#{@attributes.inspect}>"
    end

    def _apply(other)
      @type = other.type
      @key = other.key
      @name = other.name
      @attributes = other.attributes.dup
      @created_at = other.created_at
      @updated_at = other.updated_at
    end

    private

    def merge_attributes(attrs, kwargs)
      base = attrs ? attrs.dup : {}
      kwargs.each { |k, v| base[k] = v }
      base
    end

    def stringify_keys(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
    end
  end

  # Describes a flag declaration for buffered registration.
  #
  # Used by +Smplkit::ManagementClient#flags#register+ to queue declarations
  # for bulk registration. +service+ and +environment+ default to +nil+; the
  # runtime client fills them from the active +Smplkit::Client+ when it
  # forwards declarations.
  class FlagDeclaration
    attr_reader :id, :type, :default, :service, :environment

    def initialize(id:, type:, default:, service: nil, environment: nil)
      @id = id
      @type = type
      @default = default
      @service = service
      @environment = environment
      freeze
    end

    def ==(other)
      other.is_a?(FlagDeclaration) && id == other.id && type == other.type && default == other.default &&
        service == other.service && environment == other.environment
    end
    alias eql? ==

    def hash = [id, type, default, service, environment].hash
  end

  # Fluent builder for flag targeting rules.
  #
  #   Smplkit::Rule.new("Enable for enterprise users", environment: "staging")
  #     .when("user.plan", Smplkit::Op::EQ, "enterprise")
  #     .serve(true)
  #
  # Multiple +.when+ calls are AND'd. +environment:+ is required so the target
  # environment is unambiguous when the rule is passed to +Flag#add_rule+.
  # +.serve+ finalizes the rule and returns the built Hash ready to pass to
  # +add_rule+.
  class Rule
    def initialize(description, environment:)
      @description = description
      @environment = environment
      @conditions = []
    end

    # Add a condition. Multiple calls are AND'd at the top level.
    #
    # Two forms:
    #   - +when(var, op, value)+ - convenience for simple comparisons.
    #     +op+ accepts an +Op+ constant (preferred) or a raw string
    #     (e.g. +"=="+, +"contains"+).
    #   - +when(expr)+ - escape hatch accepting an arbitrary JSON Logic
    #     expression (use this for OR, nested AND/OR, +if+, etc.).
    #     See https://jsonlogic.com/ for the full expression grammar.
    def when(*args)
      if args.length == 1 && args[0].is_a?(Hash)
        @conditions << args[0]
        return self
      end

      if args.length == 3
        var, op, value = args
        op_str = op.to_s
        @conditions << if op_str == "contains"
                         { "in" => [value, { "var" => var }] }
                       else
                         { op_str => [{ "var" => var }, value] }
                       end
        return self
      end

      raise ArgumentError,
            "Rule#when takes either (var, op, value) or a single JSON Logic Hash; got args=#{args.inspect}"
    end

    # Finalize the rule with +value+ served on match and return the built Hash.
    def serve(value)
      logic =
        case @conditions.length
        when 0 then {}
        when 1 then @conditions[0]
        else { "and" => @conditions }
        end

      {
        "description" => @description,
        "logic" => logic,
        "value" => value,
        "environment" => @environment
      }
    end
  end
end
