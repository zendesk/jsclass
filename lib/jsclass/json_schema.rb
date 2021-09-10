# frozen_string_literal: true

module Jsclass
  # JSONSchema represents a JSON Schema object that can be transformed into a
  # ruby class. It also supports object referencing when using $ref JSON Schema
  # pointers.
  class JSONSchema
    include ::Jsclass::Referable

    attr_reader :document

    # initialize the instance and set up the referenced schema if there is one
    def initialize(raw_definition, document, component_name: nil)
      @component_name = component_name
      @raw_definition = raw_definition
      @document = document

      init_referenced_schema
    end

    # name returns the the main name of the JSON Schema that will be used to define
    # the constant that names the generated klass in the namespace
    # The name will use by default the JSON Schema `title` property and will
    # fall back to the given component name if any.
    # if no name is provided, it will ask the document for a new unique name in the
    # form os `Schema#{ unique_id }`
    def name
      @name ||= title || @component_name || @document.new_class_name
    end

    # combined_properties returns all the properties for this schema, even the
    # ones that are coming from composition (oneOf, allOf, anyOf) by recursively
    # inspecting each of the compositable schemas.
    def combined_properties
      @combined_properties ||= properties + properties_from_composition
    end

    private

    def properties_from_composition
      properties_from("allOf") + properties_from("anyOf") + properties_from("oneOf")
    end

    def definition_type
      if (types = definition["type"]).nil?
        "any"
      else
        types.is_a?(Array) ? types.first : types
      end
    end

    def init_referenced_schema
      return unless definition.key?("$ref")

      @referenced_schema = @document.referenced_class(
        definition.fetch("$ref")
      ).schema
    end

    # TODO, should we always validate the JSON Schema?
    # maybe this should be configurable?
    def definition
      @definition ||= @raw_definition.tap do |definition|
        JSON::Validator.validate!(metaschema, definition)
      end
    end

    def new_schema_with_preload(definition)
      new_schema(definition).tap do |schema|
        return schema unless @document.preload

        # call schema.object_class to preload the schema class instead of
        # generating classes on demand.
        # it might be convenient to preload all classes at the initialization
        # of the schema
        schema.object_class if schema.type == "object"

        # do the same for array types
        if schema.type == "array" && schema.item_schema.type == "object"
          schema.item_schema.object_class
        end
      end
    end

    def new_schema(definition)
      ::Jsclass::JSONSchema.new(definition, @document)
    end

    def metaschema
      @metaschema ||= JSON::Validator.validator_for_name("draft4").metaschema
    end
  end
end
