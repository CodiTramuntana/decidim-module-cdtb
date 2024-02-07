# frozen_string_literal: true

require "csv"

module Decidim
  module Cdtb
    module Spam
      # Detect spam behavior in users
      #
      class UserSpamDetector < ::Decidim::Cdtb::Task
        URL_REGEX = %r{(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])}.freeze

        def initialize(organization = nil)
          @organization = organization
          progress_bar = { title: "Decidim::User" }
          super("SPAM DETECTOR", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
          @users = if @organization.present?
                     Decidim::User.where(organization: @organization)
                   else
                     Decidim::User.all
                   end

          @num_users = @users.count
          log_task_info("Checking #{@num_users} users...")
        end

        def total_items
          @num_users
        end

        def do_execution(context)
          progress_bar = context[:progress_bar]

          CSV.open("spam_users.csv", "w") do |csv|
            csv_headers = ["ID", "Is suspicious?", "Name", "Email", "Nickname", "Personal URL", "About"]
            csv << csv_headers

            @users.find_each do |user|
              suspicious = "NO"

              if spam_user?(user)
                suspicious = "YES"
                @num_applied+= 1
              end

              csv << [user.id, suspicious, user.name, user.email, user.nickname, user.personal_url, user.about]

              progress_bar.increment
            end
          end
        end

        def end_execution(_ctx)
          if @num_applied.positive?
            log_task_step("#{@num_applied} suspicious users")
            log_task_step("Suspicious users list exported to spam_users.csv")
          else
            log_task_step("There are not suspicious users!!")
          end
        end

        def spam_user?(user)
          has_spam_word?(user) || has_spam_url?(user)
        end

        private

        def has_spam_word?(user)
          [user.name, user.about, user.nickname,
           user.personal_url, user.about].compact.join("||").match?(Decidim::Cdtb.config.spam_regexp)
        end

        def has_spam_url?(user)
          !!(user&.about =~ URL_REGEX || user.name =~ URL_REGEX)
        end
      end
    end
  end
end
