# frozen_string_literal: true

require "decidim/cdtb/participatory_spaces/manages_content_blocks"

module Decidim
  module Cdtb
    module ParticipatorySpaces
      # Move images to content block for participatory spaces
      class MoveImagesToContentBlock < ::Decidim::Cdtb::Task
        include ::Decidim::Cdtb::ParticipatorySpaces::ManagesContentBlocks

        def initialize(processed_models)
          progress_bar= { title: self.class.name }
          @processed_models = processed_models
          super("MOVING IMAGES...", progress_bar: progress_bar)
        end

        attr_reader :num_added

        def prepare_execution(_ctx = nil)
          @num_added= @num_items= 0

          @processed_models.each do |model_name|
            @num_items+= model_name.count
          end
          log_task_info("Moving images to content block in #{@num_items} spaces...")
        end

        def total_items
          @num_items
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          @processed_models.each do |processed_model|
            log_task_step("Processing #{processed_model}")

            spaces = processed_model

            spaces.find_each do |space|
              image_content_block = find_or_create_content_block(space, "hero")

              next if image_content_block.images.present?

              update_content_block_image(image_content_block, space.banner_image)

              @num_added += 1
              progress_bar.increment
            end
          end
        end

        def end_execution(_ctx)
          log_task_step("#{@num_added} content blocks added")
        end
      end
    end
  end
end
