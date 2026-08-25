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
end
