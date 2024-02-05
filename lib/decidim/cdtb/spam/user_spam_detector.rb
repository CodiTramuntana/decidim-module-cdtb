# frozen_string_literal: true

require "csv"

module Decidim
  module Cdtb
    module Spam
      # Detect spam behavior in users
      #
      class UserSpamDetector < ::Decidim::Cdtb::Task
        DEFAULT_SPAM_WORDS = %w[viagra sex game free crypto crack xxx luck girls vip download].freeze

        def initialize(host = nil)
          @host = host
          progress_bar = { title: "Decidim::User" }
          super("SPAM DETECTOR", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx)
          if @host.present?
            @query = Decidim::Organization.where("host ilike ?", "%#{@host}%")
            @users = Decidim::User.where(organization: @query.first)
          else
            @users = Decidim::User.all
          end

          @num_users = @users.count
          log_task_info("Checking #{@num_users} users...")
        end

        def total_items
          @num_users
        end

        def do_execution(context)
          progress_bar = context[:progress_bar]
          @suspicious_users = []

          @users.find_each do |user|
            if spam_user?(user)
              @suspicious_users << user
              @num_applied+= 1
            end

            progress_bar.increment
          end

          if @suspicious_users.present?
            export_users_to_csv
          else
            log_task_end
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

        def export_users_to_csv
          headers = ["Name", "Email", "Nickname", "Is suspicious?"]

          CSV.open("spam_users.csv", "w") do |csv|
            csv << headers

            suspicious_emails = @suspicious_users.pluck(:email)

            @users.each do |user|
              suspicious = suspicious_emails.include?(user.email) ? "✅" : "❌"
              csv << [user.name, user.email, user.nickname, suspicious]
            end
          end
        end

        def has_spam_word?(user)
          DEFAULT_SPAM_WORDS.any? do |word|
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
