# frozen_string_literal: true

module Jsclass
  # Pointer implements basic JSON Schema pointers to retrieve references inside
  # the same definition.
  class Pointer
    def initialize(pointer)
      @pointer = pointer
    end

    # find_in returns the subset for the given pointer. It fails if the pointer
    # cannot be used to retrieve a valid subset on the schema.
    # TODO: Assume we only use component references here, we will need to modify
    # this code to support full references
    def find_in(json_schema)
      # remove the first `#/` of the pointer
      dig_content(json_schema, @pointer.split("/")[1..-1])
    end

    private

    def dig_content(object, keys)
      key = keys.shift
      return object if key.nil?

      case object
      when Hash
        value = object[key] || raise_not_found(key, object, Hash)
        dig_content(value, keys)
      when Array
        value = object.at(key.to_i) || raise_not_found(key, object, Array)
        dig_content(value, keys)
      end
    end

    def raise_not_found(key, object, klass)
      raise "Invalid reference: `#{ @pointer }`. Could not find key `#{ key }` in " \
            "`#{ object }` of type `#{ klass }`"
    end
  end
end
