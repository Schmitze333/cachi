# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %i[spec rubocop]

desc 'Run specs'
RSpec::Core::RakeTask.new { |t| t.pattern = 'spec/**/*_spec.rb' }

desc 'Run rubocop'
RuboCop::RakeTask.new
