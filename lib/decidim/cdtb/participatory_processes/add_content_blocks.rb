# frozen_string_literal: true

module Decidim
  module Cdtb
    module ParticipatoryProcesses
      # Add content blocks to participatory spaces
      class AddContentBlocks < ::Decidim::Cdtb::Task
        PROCESSED_MODELS= [
          "Decidim::ParticipatoryProcess"
        ].freeze

        def initialize(content_block_names)
          progress_bar= { title: self.class.name }
          @content_block_names = content_block_names
          super("ADD CONTENT BLOCKS", progress_bar: progress_bar)
        end

        attr_reader :num_added

        def prepare_execution(_ctx = nil)
          @num_added= @num_items= 0

          PROCESSED_MODELS.each do |model_name|
            @num_items+= model_name.constantize.count
          end
          log_task_info("Adding content blocks in #{@num_items} spaces...")
        end

        def total_items
          @num_items
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          PROCESSED_MODELS.each do |space|
            log_task_step("Processing #{space.pluralize}")

            spaces = space.constantize

            @content_block_names.each do |content_block_name|
              log_task_step("Adding #{content_block_name} content block")

              spaces.find_each do |space|
                manifest = manifest_for(space)
                scope_name = manifest.content_blocks_scope_name
                scoped_resource_id = space.id
                organization = space.organization
                current_content_blocks = current_space_content_blocks(scope_name, organization, scoped_resource_id)

                new_content_block = create_content_block!(space, content_block_name, current_content_blocks)
                # extra_data content block must be down of hero image, therefore, the weight is 2
                if content_block_name == "extra_data" && space.instance_of?(Decidim::ParticipatoryProcess)
                  next if new_content_block.weight == 2 || new_content_block.weight == 20
 
                  exchange_extra_data_content_block_weight!(content_block_name, current_content_blocks)
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
          manifest = manifest_for(space)
          scope_name = manifest.content_blocks_scope_name
          scoped_resource_id = space.id
          organization = space.organization

          exists_content_block = Decidim::ContentBlock.find_by(decidim_organization_id: organization.id, scope_name:, manifest_name: content_block_name, scoped_resource_id:)

          return exists_content_block if exists_content_block.present?

          weight = (current_content_blocks.last.weight + 1) * 10

          log_task_step("Adding #{content_block_name} to #{space.slug}[#{space.id}]")

          Decidim::ContentBlock.create(
            decidim_organization_id: organization.id,
            weight:,
            scope_name:,
            scoped_resource_id:,
            manifest_name: content_block_name,
            published_at: Time.current
          )
        end
        
        def exchange_extra_data_content_block_weight!(content_block_name, current_content_blocks)
          old_content_block_with_weight = current_content_blocks.find_by(weight: [2,20])
          content_block_to_move = current_content_blocks.find_by(manifest_name: content_block_name)

          new_weight = nil

          if old_content_block_with_weight.present?
            new_weight = old_content_block_with_weight.weight
            old_content_block_with_weight.update(weight: content_block_to_move.weight)
          else
            new_weight = current_content_blocks.weight == 1 ? 2 : 20
          end

          content_block_to_move.update(weight: new_weight)
        end

        def current_space_content_blocks(scope_name, organization, scoped_resource_id)
          Decidim::ContentBlock.for_scope(scope_name, organization:).where(scoped_resource_id:)
        end

        # --------------------------------------------------
        private

        # --------------------------------------------------

        def manifest_for(resource)
          return resource.manifest if resource.is_a? Decidim::Participable
          return resource.resource_manifest if resource.is_a? Decidim::Resourceable
        end
      end
    end
  end
end
