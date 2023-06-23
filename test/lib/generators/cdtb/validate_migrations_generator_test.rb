# frozen_string_literal: true

require "test_helper"
require "generators/cdtb/validate_migrations_ci_generator"

module Cdtb
  class ValidateMigrationsCiGeneratorTest < Rails::Generators::TestCase
    tests ::Cdtb::ValidateMigrationsCiGenerator
    DEST_DIR= File.join(Dir.pwd, "tmp/generators")
    destination DEST_DIR
    setup :prepare_destination

    test "generator runs without errors" do
      assert_nothing_raised do
        run_generator ["arguments"]
      end
      assert(File.exist?(File.join(Dir.pwd, "tmp/generators", ".github/workflows/validate_migrations.yml")))
    end
  end
end
