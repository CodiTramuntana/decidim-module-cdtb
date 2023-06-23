# frozen_string_literal: true

module Decidim
  module Cdtb
    module Upgrades
      # Validates that all Decidim modules have the migrations installed.
      #
      class ValidateMigrationsTask < ::Decidim::Cdtb::Task
        def initialize
          progress_bar= { title: "Modules" }
          super("VALIDATE MODULES MIGRATIONS", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
          log_task_info("Searching gems...")

          all_railties= Rails.application.migration_railties
          railties_w_migrations= all_railties.select do |railtie|
            railtie.respond_to?(:paths) && railtie.paths["db/migrate"].first.present?
          end
          @gem_names= railties_w_migrations.map(&:railtie_name)

          log_task_info("Found #{@gem_names.size} gems with migrations...")
        end

        def total_items
          2
        end

        def pending_migrations?
          @pending_migrations
        end

        def do_execution(context)
          log_task_step("Validating...")
          progress_bar= context[:progress_bar]

          output= install_gem_migrations

          progress_bar.increment

          @pending_migrations= output.lines.select { |l| l.include?("Copied migration") }

          progress_bar.increment
        end

        def end_execution(_ctx)
          log_task_step("#{@gem_names.size} gems validated")
          log_task_failure(@pending_migrations.join("\n")) if @pending_migrations
        end

        def install_gem_migrations
          cmd= "#{Rails.root.join("bin/rails")} railties:install:migrations"
          env_vars= "FROM=#{@gem_names.join(",")}"
          `#{cmd} #{env_vars}`
        end
      end
    end
  end
end
