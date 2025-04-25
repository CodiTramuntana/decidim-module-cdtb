# frozen_string_literal: true

require_relative "install_gem_migrations_step"

module Decidim
  module Cdtb
    module Upgrades
      # Validates that all Decidim modules have the migrations installed.
      #
      class ValidateMigrationsTask < ::Decidim::Cdtb::Task
        STEPS_IN_DO_EXECUTION= 2

        def initialize
          progress_bar= { title: "Modules" }
          super("VALIDATE MODULES MIGRATIONS", progress_bar:)
        end

        def prepare_execution(_ctx)
          all_railties= Rails.application.migration_railties
          railties_w_migrations= all_railties.select do |railtie|
            railtie.respond_to?(:paths) && railtie.paths["db/migrate"].first.present?
          end
          @gem_names= railties_w_migrations.map(&:railtie_name)

          log_task_info("Found #{@gem_names.size} gems with migrations. Validating.....")
        end

        def total_items
          STEPS_IN_DO_EXECUTION
        end

        def pending_migrations?
          @pending_migrations.present?
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          output= install_gem_migrations

          progress_bar.increment

          @pending_migrations= output.lines.select { |l| l.include?("Copied migration") }

          progress_bar.increment
        end

        def end_execution(_ctx)
          log_task_step("#{@gem_names.size} gems validated")
          log_task_failure(@pending_migrations.join("\n")) if pending_migrations?
        end

        def install_gem_migrations
          install_step= InstallGemMigrationsStep.new
          install_step.install!(@gem_names)
        end
      end
    end
  end
end
