# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Decidim::Cdtb::Users::Remover do
  subject { described_class.new(organization.id, csv_path, reporter_user.email) }

  let!(:organization) { create(:organization) }
  let!(:reporter_user) { create(:user, :admin, :confirmed, organization:) }
  let!(:target_user) { create(:user, :confirmed, organization:) }
  let!(:action_log) { create(:action_log, organization:, user: target_user) }

  let(:csv_path) do
    file = Tempfile.new(["remover_spec", ".csv"])
    file.write("id\n#{target_user.id}\n")
    file.close
    file.path
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  describe "#do_execution" do
    before do
      expect(Decidim::DestroyAccount).to receive(:call).with(
        satisfy do |form|
          form.is_a?(Decidim::DeleteAccountForm) &&
            form.current_user == target_user &&
            form.delete_reason == "Confirmed spam suspicious"
        end
      )
    end

    it "blocks the user, removes their action logs and destroys their account" do
      subject.execute!

      expect(target_user.reload.blocked?).to be true
      expect(Decidim::ActionLog.where(decidim_user_id: target_user.id)).to be_empty
    end
  end

  describe "#block_user" do
    it "does not enqueue the block notification email" do
      expect do
        subject.send(:block_user, target_user, reporter_user)
      end.not_to have_enqueued_mail(Decidim::BlockUserMailer)
    end
  end

  describe "#manage_comments" do
    let!(:orphaned_comment) do
      resource = create(:dummy_resource, :published, component: create(:dummy_component, organization:))
      comment = create(:comment, author: target_user, commentable: resource, root_commentable: resource)
      comment.update_columns(decidim_participatory_space_id: nil, decidim_participatory_space_type: nil)
      resource.delete # simulates the root commentable (and its participatory space) having been removed
      comment.reload
    end

    it "skips comments without a participatory space instead of raising" do
      expect(Decidim::CreateReport).not_to receive(:call)
      expect(Decidim::Admin::HideResource).not_to receive(:call)

      expect do
        subject.send(
          :manage_comments,
          Decidim::Comments::Comment.where(id: orphaned_comment.id),
          target_user,
          reporter_user
        )
      end.not_to raise_error
    end
  end
end
