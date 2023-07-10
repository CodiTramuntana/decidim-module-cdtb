# frozen_string_literal: true

module Decidim
  module Cdtb
    module Upgrades
      # Upgrades the gems with engines in them. All, Decidim modules and standard Rails engines.
      #
      class UpgradeModulesTask < ::Decidim::Cdtb::Task
        def initialize
          progress_bar= { title: "Modules" }
          super("UPGRADE MODULES", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
          log_task_info("Have you updated the versions of your modules in the Gemfile (y/n)?")
          response= $stdin.gets
          if response&.downcase == "y"
            get the number of modules
          else
            @exit= true
          end
        end

        def total_items
          @num_users
        end

        def do_execution(context)
          # progress_bar= context[:progress_bar]

          # system("bundle update decidim")
          # system("bin/rails decidim:upgrade")
          # system("bin/rails db:migrate")
        end

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users nicknamized")
        end
      end
    end
  end
end
