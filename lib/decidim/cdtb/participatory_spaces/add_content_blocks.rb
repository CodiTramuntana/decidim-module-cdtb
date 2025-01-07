# frozen_string_literal: true

module Decidim
  module Cdtb
    module ParticipatorySpaces
      # Add content blocks to participatory spaces
      class AddContentBlocks < ::Decidim::Cdtb::Task
        def initialize(processed_models, content_block_names)
          progress_bar= { title: self.class.name }
          @processed_models = processed_models
          @content_block_names = content_block_names
          super("ADD CONTENT BLOCKS", progress_bar: progress_bar)
        end

        attr_reader :num_added

        def prepare_execution(_ctx = nil)
          @num_added= @num_items= 0

          @processed_models.each do |model_name|
            @num_items+= model_name.constantize.count
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
            log_task_step("Processing #{processed_model.pluralize}")

            spaces = processed_model.constantize

            @content_block_names.each do |content_block_name|
              log_task_step("Adding #{content_block_name} content block")

              spaces.find_each do |space|
                current_content_blocks = current_space_content_blocks(scope_name(space), space.organization, space.id)

                new_content_block = create_content_block!(space, content_block_name, current_content_blocks)
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

        def end_execution(_ctx)
          log_task_step("#{@num_added} content blocks added")
        end

        def create_content_block!(space, content_block_name, current_content_blocks)
          exists_content_block = Decidim::ContentBlock.find_by(decidim_organization_id: space.organization.id,
                                                               scope_name: scope_name(space), manifest_name: content_block_name,
                                                               scoped_resource_id: space.id)

          return exists_content_block if exists_content_block.present?

          weight = (current_content_blocks.last.weight + 1) * 10
          log_task_step("Adding #{content_block_name} to #{space.slug}[#{space.id}]")
          Decidim::ContentBlock.create(
            decidim_organization_id: space.organization.id,
            weight: weight,
            scope_name: scope_name(space),
            scoped_resource_id: space.id,
            manifest_name: content_block_name,
            published_at: Time.current
          )
        end
        # rubocop:enable Metrics/AbcSize

        # +extra_data+ content block usually be down of hero image, therefore, it's weight is 20 and all others content blocks
        # go one position down added 10
        def force_extra_data_content_block_weight!(content_block_name, current_content_blocks)
          extra_data_content_block = current_content_blocks.find_by(manifest_name: content_block_name)
          extra_data_content_block.update(weight: 20)

          current_content_blocks.each do |content_block|
            # hero is usually the first content block
            next if content_block == extra_data_content_block || content_block.manifest_name == "hero"

            content_block.update(weight: content_block.weight + 10)
          end
        end

        def current_space_content_blocks(scope_name, organization, scoped_resource_id)
          Decidim::ContentBlock.for_scope(scope_name, organization: organization).where(scoped_resource_id: scoped_resource_id)
        end

        # --------------------------------------------------
        private

        # --------------------------------------------------

        def manifest_for(resource)
          return resource.manifest if resource.is_a? Decidim::Participable
          return resource.resource_manifest if resource.is_a? Decidim::Resourceable
        end

        def scope_name(space)
          manifest_for(space).content_blocks_scope_name
        end
      end
    end
  end
end
