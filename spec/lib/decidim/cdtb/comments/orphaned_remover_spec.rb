# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Cdtb::Comments::OrphanedRemover do
  subject { described_class.new }

  let!(:organization) { create(:organization) }
  let!(:healthy_resource) { create(:dummy_resource, :published, component: create(:dummy_component, organization:)) }
  let!(:healthy_comment) { create(:comment, commentable: healthy_resource, root_commentable: healthy_resource) }

  let!(:orphaned_comment) do
    resource = create(:dummy_resource, :published, component: create(:dummy_component, organization:))
    comment = create(:comment, commentable: resource, root_commentable: resource)
    comment.update_columns(decidim_participatory_space_id: nil, decidim_participatory_space_type: nil)
    resource.delete # simulates the root commentable (and its participatory space) having been removed
    comment.reload
  end

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO decidim_comments_comment_votes
        (weight, decidim_comment_id, decidim_author_id, decidim_author_type, created_at, updated_at)
      VALUES
        (1, #{orphaned_comment.id}, #{healthy_comment.decidim_author_id}, '#{healthy_comment.decidim_author_type}', now(), now())
    SQL

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO decidim_searchable_resources (locale, resource_type, resource_id, created_at, updated_at)
      VALUES ('en', 'Decidim::Comments::Comment', #{orphaned_comment.id}, now(), now())
    SQL
  end

  it "removes orphaned comments, together with their votes and search index entries, without raising" do
    expect { subject.execute! }.not_to raise_error

    expect(Decidim::Comments::Comment.exists?(healthy_comment.id)).to be true
    expect(Decidim::Comments::Comment.exists?(orphaned_comment.id)).to be false
    expect(Decidim::Comments::CommentVote.where(decidim_comment_id: orphaned_comment.id)).to be_empty
    expect(Decidim::SearchableResource.where(resource_type: "Decidim::Comments::Comment", resource_id: orphaned_comment.id)).to be_empty
  end
end
