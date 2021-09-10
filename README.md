# Jsclass

## Description

Jsclass allows you to transform your JSON Schemas into full capable Ruby classes.

Example:

```ruby
module MyNamespace
  json_schema = <<-JSON
    {
      "title": "Person",
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        },
        "email": {
          "type": "string",
          "format": "email"
        }
      }
    }
  JSON

  Jsclass.parse(json_schema, namespace: self)
end


user = MyNamespace::Person.new(
  name: "David",
  email: "david@zendesk.com"
)
puts "Name: #{ user.name }, Email: #{ user.email }"
# will print "Name: David, Email: david@zendesk.com"

user.name = "David T"
puts user.to_h
# will print { "name" => "David T", "email" => "david@zendesk.com" }

```

## Installation

Add it to your Gemfile

```
gem "jsclass"
```

## Features

### Simplicity

Jsclass avoids using inheritance in order to generate classes with just the methods and instance variables defined in the JSON Schema. Jsclass dynamically appends the required accessors which are calculated outside the generated class namespace.

The result is a clean object that overrides only two methods (`initialize` and `to_h`), that controls the marshalling and unmarshalling of the data. The rest of the instance methods, will be accessors to the JSON Schema properties defined in the spec.

Moreover, since Jsclass doesn't have a superclass, it might be possible in the future to pass parent classes that can be used to extend the generated classes.

### Support for JSON Schema draft4

The following features are currently supported

- `properties`, `patternProperties` and `additionalProperties`.
- Metadata annotations (although we are only using `title` for now)
- Composition (`anyOf`, `allOf` and `oneOf`).
- Validation of data (via Ruby `json-schema` gem).
- Components referencing inside the schema (other type of references, like external URL or file system are not supported).

The following features are missing, but they might be added in a second phase.

- Support for OpenAPI 3.0 Schemas, which are 90% compatible, but some properties are slighty different and need to be parsed in a different way.
- Discriminators (following a similar approach as the OpenAPI spec). This will allow callers to control in more detail how polymorphic schemas (with `anyOf` or `oneOf`) are serialized.
- Filesystem URI referencing (so files can also be loaded from local paths).
- Better validation (ruby method names, required properties, format, etc.).
- Strictness configuration and coercion. As for now, the generated classes will reject data that doesn't match the expected type. So if you have defined a property with type `string`, and you pass a `Integer`, an error will be raised. We might be interested in the future in supporting multiple strategies and apply coercion rules, so values can be transformed into the destination type.

## Tests

The main rake task will run both, the `rspec` tests and `rubocop`.

```
$ rake
```

You can also run the individual tasks passing the name of the task or calling the command directly

```
$ rake spec # or rspec
$ rake rubocop # or rubocop
```
