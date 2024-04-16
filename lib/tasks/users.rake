# frozen_string_literal: true

require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :users do
    desc <<~EODESC
      Fix Decidim::User's nicknames.
    EODESC
    task fix_nicknames: [:environment] do
      fixer= ::Decidim::Cdtb::Fixes::NicknameFixer.new
      fixer.execute!
    end

    desc <<~EODESC
      Remove Decidim::User's by IDs in a CSV.
    EODESC
    task :remove, %i[csv_file] => [:environment] do |_taks, args|
      service = ::Decidim::Cdtb::Users::Remover.new(args.csv_file)
      service.execute!
    end
  end
end
