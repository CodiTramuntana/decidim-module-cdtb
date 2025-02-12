# frozen_string_literal: true

module Decidim
  module Cdtb
    module ParticipatorySpaces
      # Methods for use in participatory spaces tasks
      module ManagesContentBlocks
        # rubocop:disable Metrics/AbcSize
        def find_or_create_content_block(space, content_block_name)
          current_content_blocks = current_space_content_blocks(scope_name(space), space.organization, space.id)
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

        def update_content_block_image(content_block, image)
          content_block.manifest.images.each do |image_config|
            image_name = image_config[:name]

            next if content_block.images_container.send(image_name).present?

            content_block.images_container.send("#{image_name}=", image.blob)
            content_block.save
          end
        end

        def current_space_content_blocks(scope_name, organization, scoped_resource_id)
          Decidim::ContentBlock.for_scope(scope_name, organization: organization).where(scoped_resource_id: scoped_resource_id)
        end

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
