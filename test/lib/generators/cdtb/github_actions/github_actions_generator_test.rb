# frozen_string_literal: true

require "test_helper"
require "generators/cdtb/github_actions/github_actions_generator"

module Cdtb
  module GithubActions
    class GithubActionsGeneratorTest < Rails::Generators::TestCase
      tests ::Cdtb::GithubActions::GithubActionsGenerator
      DEST_DIR= File.join(Dir.pwd, "tmp/generators")
      destination DEST_DIR
      setup :prepare_destination

      test "validate_migrations generator runs without errors" do
        assert_nothing_raised do
          run_generator ["validate_migrations"]
        end
        assert(File.exist?(File.join(Dir.pwd, "tmp/generators", ".github/workflows/validate_migrations.yml")))
      end

      test "zeitwerk generator runs without errors" do
        assert_nothing_raised do
          run_generator ["zeitwerk"]
        end
        assert(File.exist?(File.join(Dir.pwd, "tmp/generators", ".github/workflows/zeitwerk.yml")))
      end

      test "linters generator runs without errors" do
        assert_nothing_raised do
          run_generator ["linters"]
        end
        assert(File.exist?(File.join(Dir.pwd, "tmp/generators", ".github/workflows/linters.yml")))
      end

      test "ci_app rspec generator runs without errors" do
        assert_nothing_raised do
          run_generator ["ci_app"]
        end
        assert(File.exist?(File.join(Dir.pwd, "tmp/generators", ".github/workflows/ci_app.yml")))
      end
    end
  end
end
