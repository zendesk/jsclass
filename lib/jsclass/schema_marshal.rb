# frozen_string_literal: true

module Jsclass
  # SchemaUnmarshal manages schema decoding into hashses, calling
  # getter methods for each property.
  class SchemaMarshal
    def initialize(builder, instance, options)
      @builder = builder
      @instance = instance
      @options = options
    end

    # call returns a Hash with the values
    def call
      @builder.accessor_keys.each_with_object({}) do |name, hash|
        # TODO, additionalProperties might not be initialized, and the method
        # might not exist.
        next unless @instance.respond_to?(name)

        @instance.send(name).tap do |value|
          # TODO, append the value, even if it's nil, if the schema can have a
          # null type or if it was marked as required? maybe?
          hash[name] = marshal_value(value) unless value.nil?
        end
      end
    end

    def marshal_value(value)
      case value
      when NilClass, TrueClass, FalseClass
        value
      when String
        value.to_s
      when Array
        value.map { |item| marshal_value(item) }
      when Integer
        value.to_i
      else
        value.to_h
      end
    end
  end
end
