# frozen_string_literal: true

#
# A set of utils to manage Decidim Organizations.
#
namespace :cdtb do
  namespace :upgrades do
    require "decidim/cdtb/tasks_utils"
    include Decidim::Cdtb::TasksUtils

    desc <<~EODESC
      Validates that migrations from all gems in the Gemfile have been installed.
    EODESC
    task validate_migrations: [:environment] do
      task= Decidim::Cdtb::Upgrades::ValidateMigrationsTask.new
      task.execute!
      raise("There are pending migrations") if task.pending_migrations?
    end

    namespace :hero_content_block_settings do
      require "decidim/cdtb/upgrades/hero_content_block_settings"

      desc <<~EODESC
        Export all hero content block settings to a new JSON file. Run it before upgrading to Decidim v0.31.
      EODESC
      task :export, [:path] => :environment do |_task, args|
        raise ArgumentError, "Provide a JSON file path" if args.path.blank?

        count = Decidim::Cdtb::Upgrades::HeroContentBlockSettings.export(args.path)
        puts "Exported settings for #{count} hero content blocks to #{args.path}"
      end

      desc <<~EODESC
        Restore missing hero content block settings from a JSON backup generated with the export task.
      EODESC
      task :restore, [:path] => :environment do |_task, args|
        raise ArgumentError, "Provide a JSON file path" if args.path.blank?

        count = Decidim::Cdtb::Upgrades::HeroContentBlockSettings.restore(args.path)
        puts "Processed #{count} hero content blocks from #{args.path}"
      end
    end
  end
end
