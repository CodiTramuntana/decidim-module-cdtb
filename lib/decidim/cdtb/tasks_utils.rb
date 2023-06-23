# frozen_string_literal: true

require "ruby-progressbar"

module Decidim
  module Cdtb
    # Reusable utils for Cdtb Rake tasks.
    module TasksUtils
      def logger
        Rails.logger
      end

      def do_log_info(msg)
        puts msg
        logger.info(msg)
      end

      def do_log_error(msg)
        puts msg
        logger.error(msg)
      end

      def log_task_title(title)
        do_log_info("⚙️  #{title}")
      end

      def log_task_step(description)
        do_log_info("➡️  #{description}")
      end

      def log_task_info(info)
        do_log_info("ℹ️  #{info}")
      end

      def log_task_failure(msg)
        @failed= true
        do_log_error("⚠️  #{msg}")
      end

      def log_task_end
        end_comment= if defined?(@failed) && @failed
                       "❌  Ended with errors!"
                     else
                       "✅ Done."
                     end
        do_log_info(end_comment)
      end
    end
  end
end
