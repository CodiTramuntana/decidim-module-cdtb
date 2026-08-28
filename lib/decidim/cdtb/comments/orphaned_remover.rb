# frozen_string_literal: true

module Decidim
  module Cdtb
    module Comments
      # Removes Decidim::Comments::Comment's that are orphaned: their
      # participatory space can no longer be resolved, be it because their
      # root commentable (e.g. a proposal or a meeting) was removed without
      # cascading its comments, or because the participatory space itself
      # was removed.
      #
      # This is the same condition Decidim::Cdtb::Users::Remover skips when
      # reporting/hiding comments, since Decidim::CreateReport requires a
      # participatory_space to create the Moderation.
      #
      # Rows are deleted with `delete_all` (no callbacks, no validations) on
      # purpose: Decidim::Searchable#remove_from_index blows up for these
      # comments, since it ends up calling `comment.organization.id` and
      # `organization` is nil for an orphaned comment.
      class OrphanedRemover < ::Decidim::Cdtb::Task
        def initialize
          @root_commentable_orphaned = {}
          progress_bar = { title: "Decidim::Comments::Comment" }
          super("REMOVE ORPHANED COMMENTS", progress_bar:)
        end

        def prepare_execution(_ctx)
          @num_comments = query.count
          log_task_info("Checking #{@num_comments} comments...")
        end

        def total_items
          @num_comments
        end

        def do_execution(context)
          progress_bar = context[:progress_bar]

          query.find_each do |comment|
            remove_comment(comment) if orphaned?(comment)
            progress_bar.increment
          end
        end

        def end_execution(_ctx)
          log_task_step("#{@num_applied} orphaned comments removed")
        end

        private

        # Comments that share the same root_commentable share the same fate,
        # so the check is cached by that key to avoid resolving it once per
        # comment in a heavily-commented orphaned thread. `find_each` always
        # batches by primary key, so no explicit ordering helps that cache hit.
        def query
          Decidim::Comments::Comment.all
        end

        def orphaned?(comment)
          key = [comment.decidim_root_commentable_type, comment.decidim_root_commentable_id]
          @root_commentable_orphaned.fetch(key) { @root_commentable_orphaned[key] = comment.participatory_space.blank? }
        end

        def remove_comment(comment)
          remove_moderations(comment)
          Decidim::Comments::CommentVote.where(decidim_comment_id: comment.id).delete_all
          Decidim::SearchableResource.where(resource_type: "Decidim::Comments::Comment", resource_id: comment.id).delete_all
          Decidim::Comments::Comment.where(id: comment.id).delete_all

          @num_applied += 1
          puts "OK: Comment #{comment.id} removed (orphaned)"
        end

        def remove_moderations(comment)
          moderation_ids = Decidim::Moderation.where(
            decidim_reportable_type: "Decidim::Comments::Comment",
            decidim_reportable_id: comment.id
          ).pluck(:id)
          return if moderation_ids.empty?

          Decidim::Report.where(decidim_moderation_id: moderation_ids).delete_all
          Decidim::Moderation.where(id: moderation_ids).delete_all
        end
      end
    end
  end
end
