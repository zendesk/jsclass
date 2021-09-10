# frozen_string_literal: true

require_relative "lib/jsclass/version"

Gem::Specification.new "jsclass", Jsclass::VERSION do |s|
  s.license  = "Apache-2.0"
  s.summary  = "Transform your JSON Schemas into full capable Ruby classes"
  s.authors  = [ "dtapiador@zendesk.com" ]
  s.email    = "dtapiador@zendesk.com"
  s.homepage = "https://github.com/zendesk/jsclass"

  s.add_development_dependency("bundler")
  s.add_development_dependency("pry-byebug")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rubocop")
  s.add_development_dependency("simplecov", "0.17.1")
  s.add_development_dependency("simplecov-json")

  s.add_runtime_dependency("json")
  s.add_runtime_dependency("json-schema")

  s.required_ruby_version = ">= 2.5"
  s.files = `git ls-files lib LICENSE README.md`.split("\n")
end
