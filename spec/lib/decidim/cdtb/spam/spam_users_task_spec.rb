# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Decidim::Cdtb::Spam::UserSpamDetector do
  subject { described_class.new }

  describe "#spam_user?" do
    let!(:users) { create_list :user, 6 }

    context "when the user is not spam suspicious" do
      it "returns false" do
        subject.execute!

        expect(subject.spam_user?(users.first)).to be false
      end
    end

    context "when the user is spam suspicious" do
      let!(:user) do
        create :user, nickname: "casinoFree", name: "casinoManager",
                      about: "I love free games", personal_url: "casinofree.com"
      end

      it "returns true" do
        expect(subject.spam_user?(user)).to be true
      end
    end
  end
end
