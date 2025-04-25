# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cdtb::FixNicknameJob do
  subject { described_class }

  let(:nickname) { "spec_nickname" }
  let!(:user) { create(:user, :confirmed, nickname:) }

  context "when the nickname is invalid" do
    let(:bad_nickname) { "spec nickname." }
    setup do
      user.update_attribute :nickname, bad_nickname
    end

    it "produces a valid nickname" do
      subject.perform_now(user.id)
      expect(user.reload.nickname).to eq("spec_nickname")
    end
  end
end
