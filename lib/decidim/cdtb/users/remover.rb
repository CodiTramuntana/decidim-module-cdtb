# frozen_string_literal: true

module Decidim
  module Cdtb
    module Users
      # Remove Decidim::User's
      #
      class Remover < ::Decidim::Cdtb::Task
        def initialize(csv)
          @csv = csv
        end

        def prepare_execution(_ctx); end

        def total_items; end

        def do_execution(context)
          users_id_to_remove = []

          CSV.foreach(@csv, headers: true, col_sep: ",") do |row|
            users_id_to_remove << row[0]
          end

          users_id_to_remove.each do |id|
            user = Decidim::User.find_by(id: id)

            if user.present?
              reporter_user = Decidim::User.find_by(email: "support@coditramuntana.com",
                                                    organization: user.organization)

              comments = Decidim::Comments::Comment.where(decidim_author_id: user.id)

              manage_comments(comments, reporter_user) if comments.present?
              destroy_user(user) if block_user(user, reporter_user)
            end
          end
        end

        def end_execution(_ctx)
          log_task_step("#{@num_applied} users removed")
        end

        private

        def manage_comments(comments, reporter_user)
          comments.each do |comment|
            report_comment(comment, reporter_user)
            hide_comment(comment, reporter_user)
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

        def report_comment(comment, reporter_user)
          params = {
            reason: "spam",
            details: "Spam message"
          }

          form = Decidim::ReportForm.from_params(params)

          CreateReport.call(form, comment, reporter_user) do
            on(:ok) do
              puts "OK: Comment #{comment.id} of User #{user.id} reported"
            end

            on(:invalid) do
              puts "ERROR: Comment #{comment.id} of User #{user.id} not reported"
            end
          end
        end

        def hide_comment(comment, reporter_user)
          Admin::HideResource.call(comment, reporter_user) do
            on(:ok) do
              puts "OK: Comment #{comment.id} of User #{user.id} hided"
            end

            on(:invalid) do
              puts "ERROR: Comment #{comment.id} of User #{user.id} not hided"
            end
          end
        end
      end
    end
  end
end
