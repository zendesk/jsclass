# frozen_string_literal: true

module Jsclass
  # Schema defines the ClassMethods and InstanceMethods that will be added to the
  # new generated classes.
  class Schema
    class << self
      def new_class(json_schema, document, component_name: nil)
        schema = ::Jsclass::JSONSchema.new(json_schema, document, component_name: component_name)

        Class.new.tap do |klass|
          klass.extend ::Jsclass::Schema::ClassMethods
          klass.include ::Jsclass::Schema::InstanceMethods

          klass.class_eval do
            init_schema(schema)
          end

          document.register_class(klass)
        end
      end
    end

    # ClassMethods module defines the methods that will added to the generated class.
    module ClassMethods
      attr_reader :schema

      def init_schema(schema)
        @schema = schema
        builder.parse
      end

      def marshal(instance, options)
        SchemaMarshal.new(builder, instance, options).call
      end

      def unmarshal(instance, params, options, block)
        SchemaUnmarshal.new(builder, instance, params, options, block).call
      end

      def builder
        @builder ||= SchemaBuilder.new(self)
      end

      def validate(json)
        JSON::Validator.fully_validate(@schema.raw_schema, json)
      end
    end

    # ClassMethods module defines the methods that will added to all the instances
    # of the generated class. We should keep this module as small as possible, to avoid
    # bloating the instance level and creating methods that might conflict with JSON
    # schema properties
    module InstanceMethods
      # initialize the schema and unmarshal its content.
      # note that schemas uses a hash instance variable to store the content of
      # all properties. I could have used local instance variables instead, but
      # we will need something smarter in the future if we want to support
      # diffing changes since the instance was initialized, as for instance, the
      # ruby API client is doing to detect what fields must be sent in PATCH
      # operations.
      def initialize(*params, **options, &block)
        @_properties_data = {}
        self.class.unmarshal(self, params, options, block)
      end

      def to_h(**options)
        self.class.marshal(self, options)
      end
    end
  end
end
