# frozen_string_literal: true

#
# A set of utils to manage Decidim Organizations.
#
namespace :cdtb do
  require_relative "cdtb_tasks_utils"
  include Cdtb::TasksUtils

  desc <<~EODESC
    Finds information about the Organization, or Organizations, searching by the :host_term argument ignorecase.
    Set :full (second param) to `true` for full information
  EODESC
  task :org_by_host_like, %i[host_term full] => :environment do |_task, args|
    log_task_title("ORG BY HOST LIKE")
    prepare_task

    query = Decidim::Organization.where("host ilike ?", "%#{args.host_term}%")
    log_task_step("Found #{query.count} organizations")
    query.find_each do |org|
      log_task_step("Organization [#{org.id}] #{org.name}:")
      if args.full == "true"
        do_log(org.attributes.to_yaml)
      else
        h= {
          host: org.host,
          time_zone: org.time_zone,
          locales: "#{org.default_locale} + [#{org.available_locales&.join(", ")}]",
          available_authorizations: org.available_authorizations&.join(", ")
        }
        do_log(h.to_yaml)
      end
      do_log("---------------------------------------------------------")
    end
    log_task_end
  end
end
