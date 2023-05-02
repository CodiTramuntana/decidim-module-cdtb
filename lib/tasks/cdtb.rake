# frozen_string_literal: true

require "decidim/cdtb/tasks"

namespace :cdtb do
  desc <<~EODESC
    Fix Decidim::User's nicknames.
  EODESC
  task fix_nicknames: [:environment] do
    fixer= ::Decidim::Cdtb::Fixes::NicknameFixer.new
    fixer.execute!
  end
end
