# frozen_string_literal: true

module Cdtb
  # Generates the GitHub workflow that validates that the app has the migrations from all gems already installed
  class ValidateMigrationsCiGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def copy_github_workflow_file
      copy_file "validate_migrations.yml", ".github/workflows/validate_migrations.yml"
    end
  end
end
