# frozen_string_literal: true

module Decidim
  module Cdtb
    module Users
      # Remove Decidim::User's
      #
      # rubocop:disable Metrics/ClassLength
      class Remover < ::Decidim::Cdtb::Task
        def initialize(organization_id, csv_path, reporter_user_email)
          @organization= Decidim::Organization.find_by(id: organization_id)
          @csv_path = csv_path
          @reporter_user_email = reporter_user_email
          progress_bar = { title: "Decidim::User" }
          super("USER REMOVER", progress_bar:)
        end

        def prepare_execution(_ctx); end

        def total_items
          File.open(@csv_path).readlines.size - 1
        end

        # rubocop:disable Metrics/AbcSize
        def do_execution(context)
          progress_bar = context[:progress_bar]

          reporter_user = Decidim::User.find_by(email: @reporter_user_email, organization: @organization)
          emails_on_moderations = @organization.users.where(email_on_moderations: true).pluck(:email)

          disable_email_moderations(emails_on_moderations)

          CSV.foreach(@csv_path, headers: true, col_sep: ",") do |row|
            user = Decidim::User.find_by(id: row[0])
            next unless user.present?

            comments = Decidim::Comments::Comment.where(decidim_author_id: user.id)
            manage_comments(comments, user, reporter_user) unless comments.empty?
            if block_user(user, reporter_user)
              remove_action_logs_by(user)
              destroy_user(user)
            end
            progress_bar.increment
          end
        ensure
          enable_email_moderations(emails_on_moderations)
        end
        # rubocop:enable Metrics/AbcSize

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users removed")
        end

        private

        def disable_email_moderations(users_emails)
          log_task_step("Disabling email on moderations...")

          Decidim::User.where(email: users_emails).update_all(email_on_moderations: false)
        end

        def enable_email_moderations(users_emails)
          log_task_step("Enabling email on moderations...")

          Decidim::User.where(email: users_emails).update_all(email_on_moderations: true)
        end

        def manage_comments(comments, user, reporter_user)
          comments.find_each do |comment|
            report_comment(comment, user, reporter_user) unless comment.reported?
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

        def remove_action_logs_by(user)
          puts "Removing ActionLog from user #{user.id}..."

          ActiveRecord::Base.connection.execute("DELETE FROM decidim_action_logs WHERE decidim_user_id = #{user.id}")
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
