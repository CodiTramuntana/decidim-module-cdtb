# frozen_string_literal: true

module Decidim
  module Cdtb
    module Users
      # Remove Decidim::User's
      #
      class Remover < ::Decidim::Cdtb::Task
        def initialize(csv)
          @csv = csv

          progress_bar= { title: "Decidim::User" }
          super("REMOVE USERS", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
        end

        def total_items
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]
          users_id_to_remove = [] 

          CSV.foreach((@csv), headers: true, col_sep: ",") do |row|
            users_id_to_remove << row[0]

            progress_bar.increment
          end

          byebug

              # @num_applied+= 1
        end

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users nicknamized")
        end
      end
    end
  end
end
