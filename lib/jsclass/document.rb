# frozen_string_literal: true

module Jsclass
  # Document keeps track of all the original JSON Schema and the building process
  # to load references dynamically.
  # It also registers the schema into the namespace and allows to generate unique
  # names for each JSON Schema class.
  class Document
    attr_reader :namespace, :preload

    def initialize(namespace, json_schema, preload: false)
      @namespace = namespace
      @json_schema = json_schema
      @preload = preload
      @counter = 0
    end

    # new_class_name returns a unique Key for this schema. TODO, @counter should
    # also be class based? so multiple Jsclass loading process don't conflict with the
    # main namespace
    def new_class_name
      "Schema#{ @counter += 1 }"
    end

    # register_class register the klass under the configured namespace. It fails
    # if the name has been already taken
    def register_class(klass)
      klass_name = camelize(klass.schema.name)

      if @namespace.const_defined?(klass_name)
        raise "cannot register Jsclass `#{ klass_name }`. Name has been taken " \
              "at namespace `#{ @namespace }`"
      else
        @namespace.const_set(klass_name, klass)
      end
    end

    # referenced_class returns the class for the given reference or creates a new
    # one if there is none
    def referenced_class(reference)
      classes[reference] || build_component_class(reference).tap do |klass|
        classes.store(reference, klass)
      end
    end

    private

    def classes
      @classes ||= {}
    end

    def build_component_class(reference)
      base_name = File.basename(reference)
      definition = ::Jsclass::Pointer.new(reference).find_in(@json_schema)

      ::Jsclass::Schema.new_class(definition, self, component_name: base_name)
    end

    # Camelize method stolen from ActiveSupport
    # https://github.com/rails/rails/blob/914caca2d31bd753f47f9168f2a375921d9e91cc/activesupport/lib/active_support/inflector/methods.rb#L69
    def camelize(term)
      string = term.to_s
      string = string.sub(/^[a-z\d]*/, &:capitalize)
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) do
        "#{ Regexp.last_match(1) }#{ Regexp.last_match(2).capitalize }"
      end
      string.gsub!("/", "::")
      string
    end
  end
end
