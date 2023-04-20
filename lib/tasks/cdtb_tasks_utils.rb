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
      do_log("▶️  #{title}")
    end

    def log_task_step(description)
      do_log("➡️  #{description}")
    end

    def log_task_end
      do_log("⏱️  Took #{Time.zone.now - @start_time} seconds")
      end_comment= "✅ Done."
      do_log(end_comment)
    end
  end
end
