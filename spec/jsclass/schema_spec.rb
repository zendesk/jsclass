# frozen_string_literal: true

require "spec_helper"

RSpec.describe "schema" do
  context "with a valid JSON schema with no errors" do
    let(:json_schema) do
      <<-JSON
        {
          "components": {
            "ProjectFinished": {
              "title": "project_finished",
              "type": "object",
              "properties": {
                "finished_at": {
                  "type": "string"
                }
              }
            },
            "Project": {
              "type": "object",
              "anyOf": [
                {
                  "type": "object",
                  "properties": {
                    "name": {
                      "type": "string"
                    },
                    "started_at": {
                      "type": "string"
                    }
                  }
                },
                { "$ref": "#/components/ProjectFinished" }
              ],
              "patternProperties": {
                "^label_[a-zA-Z0-9_]*$": {
                  "$ref": "#/components/Label"
                },
                "^tags_[a-zA-Z0-9]*$": {
                  "type": "string"
                }
              }
            },
            "Label": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                }
              }
            },
            "Pronouns": {
              "type": "string"
            },
            "Team": {
              "type": "object",
              "allOf": [
                { "$ref":  "#/components/Logo" }
              ],
              "properties": {
                "name": {
                  "type": "string"
                }
              }
            },
            "Logo": {
              "type": "object",
              "properties": {
                "logo_url": {
                  "type": "string",
                  "format": "url"
                }
              },
              "oneOf": [
                {
                  "type": "object",
                  "required": [ "jpg_metadata" ],
                  "properties": {
                    "jpg_metadata": {
                      "type": "string"
                    }
                  }
                },
                {
                  "type": "object",
                  "required": [ "png_metadata" ],
                  "properties": {
                    "png_metadata": {
                      "type": "string"
                    }
                  }
                }
              ]
            }
          },
          "title": "Person",
          "type": "object",
          "additionalProperties": #{ additionalProperties },
          "allOf": [
            { "$ref":  "#/components/Logo" }
          ],
          "required": [ "name", "projects" ],
          "properties": {
            "name": {
              "type": "string"
            },
            "age": {
              "type": "integer"
            },
            "is_active": {
              "type": "boolean"
            },
            "pronouns": {
              "type": "array",
              "items": {
                "$ref": "#/components/Pronouns"
              }
            },
            "projects": {
              "type": "array",
              "items": {
                "$ref": "#/components/Project"
              }
            },
            "position": {
              "type": "object",
              "properties": {
                "title": {
                  "type" : "string"
                },
                "team": {
                  "$ref": "#/components/Team"
                }
              }
            },
            "custom_settings": {}
          }
        }
      JSON
    end

    let(:additionalProperties) { true }
    let(:preload) { false }
    let(:base_class) { Class.new }
    let!(:klass) { Jsclass.parse(json_schema, namespace: base_class, preload: preload) }

    context "initializing an instance of the schema" do
      let(:base_attributes) do
        {
          "name": "david",
          "age": 40,
          "logo_url": "david.jpg",
          "is_active": true,
          "jpg_metadata": "EXIF: xxx",
          "pronouns": %w[ he him his ],
          "position": {
            "title": "Staff Eng",
            "team": {
              "name": "Redback",
              "logo_url": "redback.png",
              "png_metadata": "PNG: xxx"
            }
          },
          "projects": [
            {
              "name": "REST API Standards ADR",
              "finished_at": "2019-12-12 10:10:10",
              "label_scrum_team": {
                "name": "Redback"
              },
              "tag_product": "devplatform"
            },
            {
              "name": "ZOAS"
            }
          ],
          "random_property": "should work",
          "custom_settings": {
            "this": [ "can be" ],
            "anything": 1,
            "really": 0.1,
            "a n y t h i n g": {}
          }
        }
      end

      let(:object) { klass.new(attributes) }

      context "with no preloading" do
        it "builds the main klasses" do
          expect(base_class.const_get("Person")).to be_a Class
          expect(base_class.const_get("Logo")).to be_a Class
        end

        it "doesn't build all the lazy evaluated classes" do
          expect(base_class.const_defined?("Label")).to be false
          expect(base_class.const_defined?("Project")).to be false
          expect(base_class.const_defined?("ProjectFinished")).to be false
          expect(base_class.const_defined?("Pronouns")).to be false
          expect(base_class.const_defined?("Team")).to be false
        end
      end

      context "with klasses preloading" do
        let(:preload) { true }

        it "builds all the main klasses at the beggining" do
          expect(base_class.const_get("Label")).to be_a Class
          expect(base_class.const_get("Logo")).to be_a Class
          expect(base_class.const_get("Person")).to be_a Class
          expect(base_class.const_get("Project")).to be_a Class
          expect(base_class.const_get("ProjectFinished")).to be_a Class
          expect(base_class.const_get("Pronouns")).to be_a Class
          expect(base_class.const_get("Team")).to be_a Class
        end
      end

      context "with the default attributes" do
        let(:attributes) { base_attributes }

        it "parses the attributes correctly" do
          expect(object.name).to eq "david"
          expect(object.is_active).to eq true
          expect(object.age).to eq 40
          expect(object.logo_url).to eq "david.jpg"
          expect(object.jpg_metadata).to eq "EXIF: xxx"
          expect(object.pronouns).to eq %w[ he him his ]
          expect(object.position.title).to eq "Staff Eng"
          expect(object.position.team.name).to eq "Redback"
          expect(object.position.team.logo_url).to eq "redback.png"
          expect(object.random_property).to eq "should work"
          expect(object.projects.first.name).to eq "REST API Standards ADR"
          expect(object.projects.first.finished_at).to eq "2019-12-12 10:10:10"
          expect(object.projects.first.label_scrum_team.name).to eq "Redback"
          expect(object.projects.first.tag_product).to eq "devplatform"
          expect(object.projects.last.name).to eq "ZOAS"
          expect(object.projects.last.finished_at).to eq nil
          expect(object.custom_settings).to eq(
            "this": [ "can be" ],
            "anything": 1,
            "really": 0.1,
            "a n y t h i n g": {}
          )
        end
      end

      context "with invalid age type" do
        let(:attributes) do
          {
            "name": "david",
            "age": "invalid"
          }
        end

        it "raises an error" do
          expect { object }.to raise_error(
            "Invalid type for property `age`. Expected ancestor of `Integer`, got: `String`"
          )
        end
      end

      context "with missing required attributes" do
        let(:attributes) { base_attributes.delete_if { |key, _| key == :name } }

        it "is not valid" do
          expect(object.class.validate(object.to_h).first).to include(
            "The property '#/' did not contain a required property of 'name' in schema"
          )
        end
      end

      context "when the schema doesn't allow additionalProperties" do
        let(:additionalProperties) { false }
        let(:attributes) { base_attributes }

        it "raises an error" do
          expect { object }.to raise_error(
            "property `random_property` has not been defined for schema `Person` " \
            "and the schema does not allow additionalProperties"
          )
        end
      end
    end
  end

  context "when the schema is a invalid JSON" do
    let(:klass) { Jsclass.parse("{ invalid json }") }

    it "raises the expected error" do
      expect { klass }.to raise_error(
        "The schema is not a valid JSON. Error `809: unexpected token at " \
        "'{ invalid json }'`"
      )
    end
  end

  context "when the schema defines two properties with the same name" do
    let(:klass) do
      Jsclass.parse(<<-JSON)
        {
          "title": "SchemaWithDuplication",
          "type": "object",
          "allOf": [
            {
              "type": "object",
              "properties": {
                "example": {
                  "type": "string"
                }
              }
            }
          ],
          "properties": {
            "example": {
              "type": "string"
            }
          }
        }
      JSON
    end

    it "raises the expected error" do
      expect { klass }.to raise_error(
        "duplicated key `example` for schema `SchemaWithDuplication`"
      )
    end
  end

  context "when the schema includes invalid references" do
    let(:klass) { Jsclass.parse(json_schema) }
    let(:json_schema) do
      <<-JSON
        {
          "components": [
            { "zero": { "type": "object" } }
          ],
          "type": "object",
          "properties": {
            "zero": {
              "$ref" : "#/components/0/zero"
            },
            "one": {
              "$ref" : "#/components/0/one"
            }
          }
        }
      JSON
    end

    it "raises the expected error" do
      expect { klass }.to raise_error(
        "Invalid reference: `#/components/0/one`. Could not find key `one` in " \
        '`{"zero"=>{"type"=>"object"}}` of type `Hash`'
      )
    end
  end

  context "when the schema includes multiple sub schema with the same class name" do
    let(:klass) { Jsclass.parse(json_schema) }
    let(:json_schema) do
      <<-JSON
        {
          "components": {
            "zero": { "type": "object", "title": "SchemaZero" },
            "one": { "type": "object", "title": "SchemaZero" }
          },
          "type": "object",
          "properties": {
            "zero": {
              "$ref" : "#/components/zero"
            },
            "one": {
              "$ref" : "#/components/one"
            }
          }
        }
      JSON
    end

    it "raises the expected error" do
      expect { klass }.to raise_error(
        "cannot register Jsclass `SchemaZero`. Name has been taken at namespace `Jsclass::Schemas`"
      )
    end
  end
end
