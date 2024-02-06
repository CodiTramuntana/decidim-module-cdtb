# frozen_string_literal: true

require "csv"

module Decidim
  module Cdtb
    module Spam
      # Detect spam behavior in users
      #
      class UserSpamDetector < ::Decidim::Cdtb::Task
        include ActiveSupport::Configurable

        config_accessor :spam_words

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
            csv_headers = ["Name", "Email", "Nickname", "Is suspicious?"]
            csv << csv_headers

            @users.find_each do |user|
              suspicious = "❌"

              if spam_user?(user)
                suspicious = "✅"
                @num_applied+= 1
              end

              csv << [user.name, user.email, user.nickname, suspicious]
            end
          end

          progress_bar.increment
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
          spam_words.any? do |word|
            user.name.include?(word) || user.about&.include?(word) ||
              user.nickname.include?(word) || user.personal_url&.include?(word)
          end
        end

        def has_spam_url?(user)
          url_regex = %r{(?:https?|http)://\S+}

          !!(user&.about =~ url_regex || user.name =~ url_regex)
        end
      end
    end
  end
end
