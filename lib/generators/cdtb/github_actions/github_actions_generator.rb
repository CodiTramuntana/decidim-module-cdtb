# frozen_string_literal: true

module Cdtb
  module GithubActions
    # Generates the given GitHub workflow that validates that the app has the migrations from all gems already installed
    class GithubActionsGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def copy_github_workflow_file
        copy_file "#{file_name}.yml", ".github/workflows/#{file_name}.yml"
      end

      def replace_ruby_version
        path= File.join(Rails.root, ".ruby-version")
        return unless File.exist?(path)

        ruby_version= File.read(path).strip
        gsub_file ".github/workflows/#{file_name}.yml", /RUBY_VERSION: \d+\.\d+\.\d+/, "RUBY_VERSION: #{ruby_version}"
      end

      def replace_node_version
        path= File.join(Rails.root, ".node-version")
        return unless File.exist?(path)

        node_version= File.read(path).strip
        gsub_file ".github/workflows/#{file_name}.yml", /NODE_VERSION: \d+\.\d+\.\d+/, "NODE_VERSION: #{node_version}"
      end
    end
  end
end
