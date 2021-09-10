# frozen_string_literal: true

module Jsclass
  # Accessor manages the relation between an JSON Schema property and the
  # method name used in the instance namespace.
  # Potentially, different accessors might have the same JSON Schema, but the name
  # should be unique per generated class
  class Accessor
    attr_reader :name, :type

    # Initialize the accessor and set the method name and the schemas. Note that
    # we can potentially have several different schemas for the same key, although
    # this is not yet supported
    def initialize(name, type, schema)
      @name = name
      @type = type
      @schemas = [ schema ]
    end

    # coerce_value is called when the `#{ accessor }=` method is called. It uses
    # the accessor schema to validate the value that needs to be assigned to the
    # instance
    def coerce_value(value)
      unless coercer.valid_ancestors.any? { |ancestor| value.is_a?(ancestor) }
        raise "Invalid type for property `#{ @name }`. Expected ancestor of " \
              "`#{ coercer.valid_ancestors.join(', ') }`, got: `#{ value.class }`"
      end

      coercer.coerce(value)
    end

    # coercer uses the first schema for now. We might need to support multiple
    # schemas coercion in the future
    def coercer
      @coercer ||= @schemas.first
    end

    # add_methods defines the methods for each schema and key. The method will be
    # either a class level define method, or a singlenton one, if the schema is using
    # per instance properties (such as additionalProperties or patternProperties)
    def add_methods(receiver, key, coerce: true)
      method_creator = receiver.is_a?(Class) ? :define_method : :define_singleton_method

      # create reader method
      receiver.send(method_creator, key) { @_properties_data.fetch(key, nil) }

      # create writer method
      receiver.send(method_creator, "#{ key }=", coerce_block(coerce, key))
    end

    def coerce_block(coerce, key)
      accessor = self
      if coerce
        proc { |value| @_properties_data[key] = accessor.coerce_value(value) }
      else
        proc { |value| @_properties_data[key] = value }
      end
    end
  end
end
