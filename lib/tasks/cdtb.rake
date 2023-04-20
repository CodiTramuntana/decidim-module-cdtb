# frozen_string_literal: true

namespace :cdtb do
  require_relative "cdtb_tasks_utils"
  include Cdtb::TasksUtils

  desc <<~EODESC
    Fix Decidim::User's nicknames.
  EODESC
  task fix_nicknames: [:environment] do
    log_task_title("FIX NICKNAMES")
    prepare_task
    num_users= Decidim::User.count
    bar = ProgressBar.create(total: num_users, title: "Users")
    num_fixes = 0

    log_task_step("Starting at #{Time.zone.now}")
    log_task_step("Checking #{num_users} users...")
    Decidim::User.find_each do |user|
      Decidim::User.validators_on(:nickname).each do |validator|
        validator.validate_each(user, :nickname, user.nickname)
      end

      if user.errors[:nickname].any?
        Cdtb::FixNicknameJob.perform_later(user.id)
        num_fixes+= 1
      end
      bar.increment
    end
    log_task_step("#{num_fixes} users nicknamized")
    log_task_end
  end
end
