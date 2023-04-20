# frozen_string_literal: true

module Cdtb
  # Fixes the nickname of the Decidim::User with the given `user_id`.
  class FixNicknameJob < ApplicationJob
    queue_as :default

    def perform(user_id)
      user= Decidim::User.find(user_id)
      previous= user.nickname

      nickname = Decidim::User.nicknamize(previous, organization: user.organization)
      user.update_attribute(:nickname, nickname)

      Rails.logger.info "#{user.id}-#{user.email}: #{previous} => #{user.nickname}"
    end
  end
end
