# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Cdtb::Upgrades::ValidateMigrationsTask do
  subject { described_class.new }

  describe "#pending_migrations?" do
    before do
      step_double= double("InstallGemMigrationsStep double")
      expect(step_double).to receive(:install!).with(anything).and_return(output)
      expect(Decidim::Cdtb::Upgrades::InstallGemMigrationsStep).to receive(:new).and_return(step_double)

      subject.execute!
    end

    context "when all migrations are installed" do
      let(:output) do
        # rubocop: disable Layout/LineLength
        "NOTE: Migration 20170806125915_create_active_storage_tables.rb from active_storage has been skipped. Migration with the same name already exists.\n"
        # rubocop: enable Layout/LineLength
      end

      it "returns false" do
        expect(subject.pending_migrations?).to be false
      end
    end

    context "when some migrations are missing" do
      let(:output) do
        # rubocop: disable Layout/LineLength
        "Copied migration 20230630103500_create_decidim_verifications_csv_emails.decidim_verifications_csv_email.rb from decidim_verifications_csv_email"
        # rubocop: enable Layout/LineLength
      end

      it "returns true" do
        expect(subject.pending_migrations?).to be true
      end
    end
  end
end
