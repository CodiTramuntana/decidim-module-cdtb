# frozen_string_literal: true

#
# A set of utils to manage Decidim Organizations.
#
namespace :cdtb do
  require "decidim/cdtb/tasks_utils"
  include Decidim::Cdtb::TasksUtils

  desc <<~EODESC
    Finds information about the Organization, or Organizations, searching by the :host_term argument ignorecase.
    Set :full (second param) to `true` for full information
  EODESC
  task :org_by_host_like, %i[host_term full] => :environment do |_task, args|
    task= Decidim::Cdtb::Multitenants::OrgByHostLike.new(args.host_term, args.full)
    task.execute!
  end
end
