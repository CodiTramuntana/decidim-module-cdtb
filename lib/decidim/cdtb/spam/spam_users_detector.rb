# frozen_string_literal: true

require "csv"

module Decidim
  module Cdtb
    module Spam
      # Detect spam behavior in users
      #
      class SpamUsersDetector < ::Decidim::Cdtb::Task
        # rubocop:disable Style/RedundantRegexpEscape
        URL_REGEX = %r{(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|
        www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|
        (?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})}
        # rubocop:enable Style/RedundantRegexpEscape

        def initialize(organization = nil)
          @organization = organization
          progress_bar = { title: "Decidim::User" }
          super("SPAM DETECTOR", progress_bar:)
        end

        def prepare_execution(_ctx)
          base_query = Decidim::User.where(deleted_at: nil)

          @users = if @organization.present?
                     base_query.where(organization: @organization)
                   else
                     base_query
                   end

          @num_users = @users.count
          log_task_info("Checking #{@num_users} users...")
        end

        def total_items
          @num_users
        end

        # rubocop:disable Metrics/AbcSize
        def do_execution(context)
          progress_bar = context[:progress_bar]
          filename= "spam_users.csv"
          filepath= Rails.env.test? ? "tmp/#{filename}" : filename
          CSV.open(filepath, "w") do |csv|
            csv_headers = ["ID", "Is suspicious?", "Name", "Email", "Nickname", "Personal URL", "About",
                           "Organization ID", "Organization Name", "Last Sign In At"]
            csv << csv_headers

            @users.find_each do |user|
              suspicious = "NO"

              if spam_user?(user)
                suspicious = "YES"
                @num_applied+= 1
              end

              csv << [user.id, suspicious, user.name, user.email, user.nickname, user.personal_url, user.about,
                      user.organization.id, user.organization.name, user.last_sign_in_at&.strftime(Decidim::Cdtb::STRFTIME_FORMAT)]

              progress_bar.increment
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

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
