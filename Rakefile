# frozen_string_literal: true

require "rubocop/rake_task"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]
