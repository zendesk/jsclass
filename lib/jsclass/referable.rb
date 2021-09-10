# frozen_string_literal: true

module Jsclass
  # Referable module defines all the methods that can be delegated to the
  # referenced JSON Schema if `$ref` has been used
  module Referable
    class << self
      # reference_method creates a method that will redirect some of the methods
      # to the referenced class if the JSON Schema is using a reference
      def reference_method(name, &block)
        define_method(name) do |*args|
          return instance_exec(*args, &block) if @referenced_schema.nil?

          @referenced_schema.send(name, *args)
        end
      end
    end

    reference_method(:title) do
      @title ||= definition.fetch("title", nil)
    end

    reference_method(:raw_schema) do
      @raw_definition
    end

    reference_method(:properties) do
      @properties ||= definition.fetch("properties", {}).map do |name, child|
        [ name, new_schema_with_preload(child) ]
      end
    end

    reference_method(:properties_from) do |key|
      definition.fetch(key, {}).reduce([]) do |properties, child|
        # do not use preload for combined_properties. The schemas for
        # this properties will be preloaded by the actual schema
        # of the child definition.
        properties + new_schema(child).combined_properties
      end
    end

    reference_method(:type) do
      @type ||= definition_type
    end

    reference_method(:additional_properties_allowed?) do
      definition["additionalProperties"] != false
    end

    reference_method(:item_schema) do
      @item_schema ||= new_schema_with_preload(definition.fetch("items", {}))
    end

    reference_method(:pattern_properties) do
      @pattern_properties ||= definition.fetch("patternProperties", {}).map do |name, child|
        [ name, new_schema_with_preload(child) ]
      end
    end

    # object_class can be lazy loaded
    reference_method(:object_class) do
      @object_class ||= ::Jsclass::Schema.new_class(definition, @document)
    end

    reference_method(:coerce) do |value|
      case type
      when "string"
        value.to_s
      when "object"
        object_class.new(value)
      when "array"
        value.map { |child| item_schema.coerce(child) }
      when "integer"
        value.to_i
      else # including :any or :boolean, though boolean should ensure it's true or fallback to false
        value
      end
    end

    reference_method(:valid_ancestors) do
      case type
      when "string"
        [ String ]
      when "object"
        [ Hash ]
      when "array"
        [ Array ]
      when "integer"
        [ Integer ]
      when "boolean"
        [ TrueClass, FalseClass ]
      else
        [ Object ]
      end
    end
  end
end
