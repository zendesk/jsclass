# frozen_string_literal: true

module Jsclass
  # SchemaUnmarshal manages schema encoding into instances, calling
  # setter methods for each property with the provided value .
  class SchemaUnmarshal
    def initialize(builder, instance, parameters, options, block)
      @builder = builder
      @instance = instance
      @parameters = parameters
      @options = options
      @block = block
    end

    # call deserializes the values into the given instance.
    def call
      from_hash if hash_definition.any?

      instance_exec(&@block) unless @block.nil?
    end

    private

    # Parse the given hash. Iterate over all the valid properties from the
    # values and use / build accessors on demand.
    def from_hash
      each_valid_property do |key, value, accessor|
        case accessor.type
        when :pattern_property
          # TODO, key might not be a valid ruby method?
          accessor.add_methods(@instance, key.to_s)
          @builder.accessors.store(key, accessor)
        when :additional_property
          # TODO, key might not be a valid ruby method?
          accessor.add_methods(@instance, key.to_s, coerce: false)
          @builder.accessors.store(key, accessor)
        end

        @instance.send("#{ key }=", value)
      end
    end

    def each_valid_property
      hash_definition.each do |key, value|
        if @builder.static_accessors.key?(key.to_s)
          yield key, value, @builder.static_accessors.fetch(key.to_s)
        elsif !(accessor = @builder.pattern_accessor(key)).nil?
          yield key, value, accessor
        else
          yield(*extract_unkown_property(key, value))
        end
      end
    end

    def extract_unkown_property(key, value)
      if @instance.class.schema.additional_properties_allowed?
        document = @instance.class.schema.document
        accessor = @builder.find_or_add_dynamic_accessor(key) do
          ::Jsclass::Accessor.new(
            key, :additional_property,
            ::Jsclass::JSONSchema.new({}, document)
          )
        end

        [ key, value, accessor ]
      else
        raise(
          "property `#{ key }` has not been defined for schema " \
          "`#{ @instance.class.schema.name }` and the schema does not allow " \
          "additionalProperties"
        )
      end
    end

    def hash_definition
      @hash_definition ||= @parameters.first.is_a?(Hash) ? @parameters.first : @options
    end
  end
end
