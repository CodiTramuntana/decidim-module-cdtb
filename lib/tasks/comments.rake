# frozen_string_literal: true

require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :comments do
    desc <<~EODESC
      Remove orphaned Decidim::Comments::Comment's: comments whose participatory
      space can no longer be resolved (their root commentable and/or their
      participatory space has been removed).
    EODESC
    task remove_orphaned: [:environment] do
      task = Decidim::Cdtb::Comments::OrphanedRemover.new
      task.execute!
    end
  end
end
