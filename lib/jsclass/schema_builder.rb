# frozen_string_literal: true

module Jsclass
  # SchemaBuilder sets the different accessors and keeps track of them, so we
  # always know what are the accepted properties of one class
  class SchemaBuilder
    attr_reader :pattern_accessors, :static_accessors, :accessors

    def initialize(klass)
      @klass = klass
      @accessors = {}
      @static_accessors = {}
      @pattern_accessors = {}
      @dynamic_accessors = {}
    end

    # return all the accessor keys. Note that the same accessor can have
    # multiple entries (like pattern entries), so this is calculated from both
    # the static accessors hash and the accessor
    def accessor_keys
      @static_accessors.keys + @accessors.keys
    end

    # parse creates accessors for all the schema properties.
    def parse
      @klass.schema.combined_properties.each do |name, schema|
        add_accessors(name, schema)
      end

      @klass.schema.pattern_properties.each do |name, schema|
        @pattern_accessors.store(name, ::Jsclass::Accessor.new(name, :pattern_property, schema))
      end
    end

    def find_or_add_dynamic_accessor(key, &block)
      @dynamic_accessors[key] || block.call.tap do |accessor|
        @dynamic_accessors.store(key, accessor)
      end
    end

    # add_accessors sets up the accessor for the given key and property
    # TODO: we need to rewrite this to support multiple schemas in one accessor
    # (for instance, if the JSON schema uses composition that affect the same property,
    def add_accessors(name, schema)
      if @static_accessors.key?(name)
        raise(
          "duplicated key `#{ name }` for schema `#{ @klass.schema.name }`"
        )
      else
        ::Jsclass::Accessor.new(name, :static, schema).tap do |accessor|
          accessor.add_methods(@klass, name)

          @static_accessors.store(name, accessor)
        end
      end
    end

    # pattern_accessors returns the schema patternProperties that match the given
    # key
    def pattern_accessor(key)
      @pattern_accessors.each do |accessor_key, accessor|
        return accessor if key.to_s.match?(accessor_key)
      end
      nil
    end
  end
end
