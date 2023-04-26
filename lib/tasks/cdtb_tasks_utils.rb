# frozen_string_literal: true

require "ruby-progressbar"

module Cdtb
  # Reusable utils for Cdtb Rake tasks.
  module TasksUtils
    def logger
      Rails.logger
    end

    def prepare_task
      @start_time= Time.zone.now
    end

    def do_log(msg)
      puts msg
      logger.info(msg)
    end

    def log_task_title(title)
      do_log("⚙️  #{title}")
    end

    def log_start_steps(title:, total: 0, &block)
      do_log("▶️  Starting at #{Time.zone.now}")
      bar = ProgressBar.create(total: total, title: title)
      block.call(bar)
      do_log("⏱️  Took #{Time.zone.now - @start_time} seconds")
    end

    def log_task_step(description)
      do_log("➡️  #{description}")
    end

    def log_task_info(info)
      do_log("ℹ️  #{info}")
    end

    def log_task_end
      end_comment= "✅ Done."
      do_log(end_comment)
    end
  end
end
