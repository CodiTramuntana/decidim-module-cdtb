# frozen_string_literal: true

namespace :cdtb do
  namespace :anonymize do
    desc "Checks for the environment"
    task :check do
      raise "Won't run unless the env var DISABLE_PRODUCTION_CHECK=1 is set" unless ENV["DISABLE_PRODUCTION_CHECK"]
    end

    desc "Anonymizes a production dump."
    task all: %i[users user_groups system_admins paper_trail]

    def with_progress(collection, name:)
      total = collection.count
      progressbar = create_progress_bar(total:)

      puts "Anonymizing #{total} #{name}...\n"
      skip_logs do
        collection.find_each do |item|
          yield(item)
          progressbar.increment
        end
      end
    end

    def create_progress_bar(total:)
      ProgressBar.create(
        progress_mark: " ",
        remainder_mark: "\u{FF65}",
        total:,
        format: "%a %e %b\u{15E7}%i %p%% %t"
      )
    end

    def skip_logs
      previous_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = 2
      yield
      ActiveRecord::Base.logger.level = previous_log_level
    end

    task proposals: %i[check environment] do
      Decidim::Proposals::ProposalVote.delete_all

      with_progress(Decidim::Proposals::Proposal.all, name: "proposals") do |proposal|
        proposal.votes.delete_all
      end
      Decidim::Proposals::Proposal.update_all(proposal_votes_count: 0)
    end

    task users: %i[check environment] do
      with_progress Decidim::User.where.not(admin: true), name: "users" do |user|
        user.update_columns(
          email: "email#{user.id}@example.org",
          name: "Anonymized User #{user.id}",
          nickname: "anon-#{user.id}",
          encrypted_password: "encryptedpassword#{user.id}",
          reset_password_token: nil,
          current_sign_in_at: nil,
          last_sign_in_at: nil,
          current_sign_in_ip: nil,
          last_sign_in_ip: nil,
          invitation_token: nil,
          confirmed_at: Time.zone.now,
          confirmation_token: nil,
          unconfirmed_email: nil,
          avatar: nil
        )

        user.update_columns(extra: {}) if user.attributes["extra"].present?

        user.identities.find_each do |identity|
          identity.update_columns(uid: "anonymized-identity-#{identity.id}")
        end

        Decidim::Authorization.where(user:).find_each do |authorization|
          authorization.update_columns(unique_id: authorization.id)
        end
      end
    end

    task user_groups: %i[check environment] do
      with_progress Decidim::UserGroup.all, name: "user groups" do |user_group|
        user_group.update_columns(
          email: "email-ug-#{user_group.id}@example.org",
          name: "User Group #{user_group.id}",
          nickname: "anon-ug-#{user_group.id}",
          encrypted_password: "encryptedpassword#{user_group.id}",
          reset_password_token: nil,
          current_sign_in_at: nil,
          last_sign_in_at: nil,
          current_sign_in_ip: nil,
          last_sign_in_ip: nil,
          invitation_token: nil,
          confirmed_at: Time.zone.now,
          confirmation_token: nil,
          unconfirmed_email: nil,
          avatar: nil,
          extended_data: user_group.extended_data.merge({
                                                          phone: "123456789",
                                                          document_number:
                                                          "document-#{user_group.id}"
                                                        })
        )

        user_group.update_columns(extra: {}) if user_group.attributes["extra"].present?
      end
    end

    task system_admins: %i[check environment] do
      with_progress Decidim::System::Admin.all, name: "system admins" do |admin|
        admin.update_columns(
          email: "email-admin#{admin.id}@example.org",
          encrypted_password: "encryptedpassword#{admin.id}",
          reset_password_token: nil,
          unlock_token: nil
        )
      end
    end

    task paper_trail: %i[check environment] do
      PaperTrail::Version
        .where(item_type: %w[Decidim::Authorization Decidim::UserBaseEntity Decidim::UserGroup])
        .delete_all
    end
  end
end
