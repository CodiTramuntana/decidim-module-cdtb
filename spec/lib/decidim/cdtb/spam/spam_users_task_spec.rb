# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Decidim::Cdtb::Spam::UserSpamDetector do
  describe "#spam_user? without organization" do
    before do
      subject { described_class.new }
    end

    context "when the user is not spam suspicious" do
      let!(:users) { create_list :user, 6 }

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
        subject.execute!
        expect(subject.spam_user?(user)).to be true
      end
    end
  end

  describe "#spam_user? with organization" do
    let!(:organization) { create(:organization) }

    before do
      subject { described_class.new(organization) }
    end
    
    context "when the user is not spam suspicious" do
      let!(:users) { create_list :user, 6, organization: organization }

      it "returns false" do
        subject.execute!

        expect(subject.spam_user?(users.first)).to be false
      end
    end

    context "when the user is spam suspicious" do
      let!(:user) do
        create :user, nickname: "cryptoWave", name: "CRPW",
                      about: "Do you know about cryptos?", personal_url: "crpw.com", organization: organization
      end

      it "returns true" do
        subject.execute!

        expect(subject.spam_user?(user)).to be true
      end
    end
  end
end
