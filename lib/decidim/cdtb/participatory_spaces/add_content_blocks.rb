# frozen_string_literal: true

require "decidim/cdtb/participatory_spaces/manages_content_blocks"

module Decidim
  module Cdtb
    module ParticipatorySpaces
      # Add content blocks to participatory spaces
      class AddContentBlocks < ::Decidim::Cdtb::Task
        include ::Decidim::Cdtb::ParticipatorySpaces::ManagesContentBlocks

        def initialize(processed_models, content_block_names)
          progress_bar= { title: self.class.name }
          @processed_models = processed_models
          @content_block_names = content_block_names
          super("ADD CONTENT BLOCKS", progress_bar:)
        end

        attr_reader :num_added

        def prepare_execution(_ctx = nil)
          @num_added= @num_items= 0

          @processed_models.each do |model_name|
            @num_items+= model_name.count
          end
          log_task_info("Adding content blocks in #{@num_items} spaces...")
        end

        def total_items
          @num_items
        end

        # rubocop:disable Metrics/AbcSize
        def do_execution(context)
          progress_bar= context[:progress_bar]

          @processed_models.each do |processed_model|
            log_task_step("Processing #{processed_model}")

            spaces = processed_model

            @content_block_names.each do |content_block_name|
              log_task_step("Adding #{content_block_name} content block")

              spaces.find_each do |space|
                current_content_blocks = current_space_content_blocks(scope_name(space), space.organization, space.id)

                new_content_block = find_or_create_content_block(space, content_block_name)
                if content_block_name == "extra_data" && space.instance_of?(Decidim::ParticipatoryProcess)
                  next if new_content_block.weight == 20

                  force_extra_data_content_block_weight!(content_block_name, current_content_blocks)
                end

                @num_added += 1
                progress_bar.increment
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def end_execution(_ctx)
          log_task_step("#{@num_added} content blocks added")
        end

        # +extra_data+ content block usually be down of hero image, therefore, it's weight is 20 and all others content blocks
        # go one position down added 10
        def force_extra_data_content_block_weight!(content_block_name, current_content_blocks)
          extra_data_content_block = current_content_blocks.find_by(manifest_name: content_block_name)
          extra_data_content_block.update(weight: 20)

          current_content_blocks.each do |content_block|
            # hero is usually the first content block
            next if content_block.nil?
            next if content_block == extra_data_content_block || content_block.manifest_name == "hero"

            content_block.update(weight: content_block.weight + 10)
          end
        end
      end
    end
  end
end
