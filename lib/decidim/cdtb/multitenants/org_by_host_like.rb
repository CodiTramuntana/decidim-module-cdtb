# frozen_string_literal: true

module Decidim
  module Cdtb
    module Multitenants
      # Finds information about the Organization, or Organizations, searching by the :host_term argument ignorecase.
      # Set :full (second param) to `true` for full information
      #
      class OrgByHostLike < ::Decidim::Cdtb::Task
        def initialize(host_term, full_info)
          @host_term= host_term
          @show_full_info= full_info == "true"
          super("ORG BY HOST LIKE")
        end

        def prepare_execution(_ctx)
          @query = Decidim::Organization.where("host ilike ?", "%#{@host_term}%")
          log_task_info("Found #{@query.count} organizations")
        end

        def do_execution(_ctx)
          @query.find_each do |org|
            log_task_step("Organization [#{org.id}] #{org.name}:")
            if show_full_info?
              show_full_info(org)
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
        end

        #----------------------------------------------------------------

        private

        #----------------------------------------------------------------

        def show_full_info?
          @show_full_info
        end

        def show_full_info(org)
          do_log(org.attributes.to_yaml)
        end

        def show_summary_info(org)
          h= {
            host: org.host,
            time_zone: org.time_zone,
            locales: "#{org.default_locale} + [#{org.available_locales&.join(", ")}]",
            available_authorizations: org.available_authorizations&.join(", ")
          }
          do_log(h.to_yaml)
        end
      end
    end
  end
end
