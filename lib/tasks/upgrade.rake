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
  end
end
