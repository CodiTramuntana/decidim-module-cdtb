# frozen_string_literal: true

module Decidim
  module Cdtb
    module Users
      # Remove Decidim::User's
      #
      # rubocop:disable Metrics/ClassLength
      class Remover < ::Decidim::Cdtb::Task
        def initialize(csv_path, reporter_user_email)
          @csv_path = csv_path
          @reporter_user_email = reporter_user_email
          progress_bar = { title: "Decidim::User" }
          super("USER REMOVER", progress_bar: progress_bar)
        end

        def prepare_execution(_ctx); end

        def total_items
          File.open(@csv_path).readlines.size - 1
        end

        # rubocop:disable Metrics/AbcSize
        def do_execution(context)
          progress_bar = context[:progress_bar]

          users_with_email_on_moderations = Decidim::User.where(email_on_moderations: true).pluck(:email)

          disable_email_moderations(users_with_email_on_moderations)

          CSV.foreach(@csv_path, headers: true, col_sep: ",") do |row|
            user = Decidim::User.find_by(id: row[0])
            next unless user.present?

            reporter_user = Decidim::User.find_by(email: @reporter_user_email,
                                                  organization: user.organization)
            comments = Decidim::Comments::Comment.where(decidim_author_id: user.id)
            manage_comments(comments, user, reporter_user) unless comments.empty?
            destroy_user(user) if block_user(user, reporter_user)
            progress_bar.increment
          end
        ensure
          enable_email_moderations(users_with_email_on_moderations)
        end
        # rubocop:enable Metrics/AbcSize

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users removed")
        end

        private

        def disable_email_moderations(users_email)
          log_task_step("Disabling email on moderations...")

          users = Decidim::User.where(email: users_email)

          users.find_each do |user|
            user.email_on_moderations = false
            user.save(validate: false)
          end
        end

        def enable_email_moderations(users_email)
          log_task_step("Enabling email on moderations...")

          users = Decidim::User.where(email: users_email)

          users.find_each do |user|
            user.email_on_moderations = true
            user.save(validate: false)
          end
        end

        def manage_comments(comments, user, reporter_user)
          comments.find_each do |comment|
            report_comment(comment, user, reporter_user)
            hide_comment(comment, user, reporter_user) unless comment.hidden?
          end
        end

        def block_user(user, reporter_user)
          params = {
            user_id: user.id,
            justification: "Confirmed spam suspicious"
          }

          form = Decidim::Admin::BlockUserForm.from_params(params).with_context(
            {
              current_organization: user.organization,
              current_user: reporter_user
            }
          )

          Decidim::Admin::BlockUser.call(form) do
            on(:ok) do
              puts "OK: User #{user.id} blocked"
              return true
            end

            on(:invalid) do
              puts "ERROR: User #{user.id} not blocked"
              return false
            end
          end
        end

        def destroy_user(user)
          params = {
            delete_reason: "Confirmed spam suspicious"
          }

          form = Decidim::DeleteAccountForm.from_params(params)

          Decidim::DestroyAccount.call(user, form) do
            on(:ok) do
              puts "OK: User #{user.id} removed"
            end

            on(:invalid) do
              puts "ERROR: User #{user.id} not removed"
            end
          end
        end

        def report_comment(comment, user, reporter_user)
          params = {
            reason: "spam",
            details: "Spam message"
          }

          form = Decidim::ReportForm.from_params(params).with_context(context_for_report(user, comment, reporter_user))
          reportable = GlobalID::Locator.locate_signed(comment.to_sgid.to_s)

          Decidim::CreateReport.call(form, reportable, reporter_user) do
            on(:ok) do
              puts "OK: Comment #{comment.id} of User #{user.id} reported"
            end

            on(:invalid) do
              puts "ERROR: Comment #{comment.id} of User #{user.id} not reported"
            end
          end
        end

        def hide_comment(comment, user, reporter_user)
          Admin::HideResource.call(comment, reporter_user) do
            on(:ok) do
              puts "OK: Comment #{comment.id} of User #{user.id} hided"
            end

            on(:invalid) do
              puts "ERROR: Comment #{comment.id} of User #{user.id} not hided"
            end
          end
        end

        def context_for_report(user, comment, reporter_user)
          {
            current_organization: user.organization,
            current_component: comment.component,
            current_user: reporter_user,
            current_participatory_space: comment.participatory_space
          }
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
