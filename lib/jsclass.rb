# frozen_string_literal: true

require "json-schema"

# Jsclass module is the main namespace and provides the `parse` method entry point
# to decode any JSON Schema into a ruby class
module Jsclass
  class << self
    def parse(schema, namespace: ::Jsclass::Schemas, preload: false)
      json_schema = JSON.parse(schema)
      document = ::Jsclass::Document.new(namespace, json_schema, preload: preload)

      ::Jsclass::Schema.new_class(json_schema, document)
    rescue ::JSON::ParserError => e
      raise "The schema is not a valid JSON. Error `#{ e }`"
    end
  end

  # Jsclass::Schemas is the default namespace if the caller doesn't pass a custom
  # namespace
  module Schemas
  end
end

require_relative "jsclass/accessor"
require_relative "jsclass/referable"
require_relative "jsclass/json_schema"
require_relative "jsclass/document"
require_relative "jsclass/pointer"
require_relative "jsclass/schema"
require_relative "jsclass/schema_builder"
require_relative "jsclass/schema_marshal"
require_relative "jsclass/schema_unmarshal"
require_relative "jsclass/version"
