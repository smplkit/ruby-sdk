# frozen_string_literal: true

module Smplkit
  module Management
    # An environment resource — a customer-defined deploy target (production,
    # staging, etc.) for which configs and flags can have overrides.
    class Environment
      attr_accessor :id, :key, :name, :color, :classification, :description, :created_at, :updated_at

      def initialize(client = nil, key:, id: nil, name: nil, color: nil,
                     classification: EnvironmentClassification::STANDARD,
                     description: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @key = key
        @name = name
        @color = color
        @classification = classification
        @description = description
        @created_at = created_at
        @updated_at = updated_at
      end

      def save
        raise "Environment was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_environment(self)
          else
            @client._update_environment(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      def delete
        raise "Environment was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      def _apply(other)
        @id = other.id
        @key = other.key
        @name = other.name
        @color = other.color
        @classification = other.classification
        @description = other.description
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # A context type resource (e.g. "user", "account").
    class ContextType
      attr_accessor :id, :key, :name, :description, :created_at, :updated_at

      def initialize(client = nil, key:, id: nil, name: nil, description: nil,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @key = key
        @name = name
        @description = description
        @created_at = created_at
        @updated_at = updated_at
      end

      def save
        raise "ContextType was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_context_type(self)
          else
            @client._update_context_type(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      def delete
        raise "ContextType was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      def _apply(other)
        @id = other.id
        @key = other.key
        @name = other.name
        @description = other.description
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # A service resource — a backend application or microservice in the
    # customer's stack that contexts can be evaluated against.
    class Service
      attr_accessor :id, :key, :name, :created_at, :updated_at

      def initialize(client = nil, key:, id: nil, name: nil,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @key = key
        @name = name
        @created_at = created_at
        @updated_at = updated_at
      end

      def save
        raise "Service was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_service(self)
          else
            @client._update_service(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      def delete
        raise "Service was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      def _apply(other)
        @id = other.id
        @key = other.key
        @name = other.name
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # An account-wide settings resource.
    class AccountSettings
      attr_accessor :id, :environment_order, :default_environment, :updated_at

      def initialize(client = nil, id: nil, environment_order: nil,
                     default_environment: nil, updated_at: nil)
        @client = client
        @id = id
        @environment_order = environment_order || []
        @default_environment = default_environment
        @updated_at = updated_at
      end

      def save
        raise "AccountSettings was constructed without a client; cannot save" if @client.nil?

        updated = @client._update_account_settings(self)
        _apply(updated)
        self
      end
      alias save! save

      def _apply(other)
        @id = other.id
        @environment_order = other.environment_order
        @default_environment = other.default_environment
        @updated_at = other.updated_at
      end
    end
  end
end
