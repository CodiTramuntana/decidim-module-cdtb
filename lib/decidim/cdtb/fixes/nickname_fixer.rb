# frozen_string_literal: true

module Decidim
  module Cdtb
    module Fixes
      # Fixes invalid Decidim::User#nickname
      #
      class NicknameFixer < ::Decidim::Cdtb::Task
        def initialize
          progress_bar= { title: "Decidim::User" }
          super("FIX NICKNAMES", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
          @num_users= Decidim::User.count
          log_task_info("Checking #{@num_users} users...")
        end

        def total_items
          @num_users
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          Decidim::User.find_each do |user|
            Decidim::User.validators_on(:nickname).each do |validator|
              validator.validate_each(user, :nickname, user.nickname)
            end

            if user.errors[:nickname].any?
              ::Cdtb::FixNicknameJob.perform_later(user.id)
              @num_applied+= 1
            end
            progress_bar.increment
          end
        end

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users nicknamized")
        end
      end
    end
  end
end
