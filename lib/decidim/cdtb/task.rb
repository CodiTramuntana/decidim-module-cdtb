# frozen_string_literal: true

require "decidim/cdtb/tasks_utils"

module Decidim
  module Cdtb
    # Parent class with common behaviour for all tasks.
    #
    class Task
      include Decidim::Cdtb::TasksUtils

      # title: The title shown at the begining of the Task
      # progress_bar: A hash with one key: :title for the title of the ProgressBar.
      def initialize(title, progress_bar: nil)
        @title= title
        @progress_bar= progress_bar
        @num_applied = 0
      end

      attr_reader :num_applied, :title

      def init
        log_task_title(@title)
        @start_time= Time.zone.now
        do_log("▶️  Starting at #{@start_time}")
      end

      def execute!
        init
        ctx= {}
        ctx[:progress_bar]= ProgressBar.create(total: total_items, title: title) if has_progress?
        prepare_execution(ctx)
        do_execution(ctx)
        end_execution(ctx)
        finish
      end

      def finish
        do_log("⏱️  Took #{Time.zone.now - @start_time} seconds")
        log_task_end
      end

      #################################

      protected

      #################################

      # May be used by sublasses for preparing before executing the task
      def prepare_execution(context); end

      # Sublasses must implement the steps of the task overriding this method.
      def do_execution(context); end

      # May be used by sublasses for doing whatever after executing the task
      def end_execution(context); end

      def has_progress?
        @progress_bar.present?
      end

      # The number of items to be processed.
      # Required by the progress bar.
      def total_items; end
    end
  end
end
