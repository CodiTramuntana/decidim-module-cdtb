# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Decidim::Cdtb::Upgrades::HeroContentBlockSettings do
  let(:organization) { create(:organization) }
  let!(:hero) do
    create(:content_block, organization:, scope_name: :homepage, manifest_name: :hero,
                           settings: { "welcome_text_en" => "Hello", "cta_button_text_en" => "Old CTA" })
  end
  let!(:other_block) do
    create(:content_block, organization:, scope_name: :homepage, manifest_name: :html, settings: { "html_content_en" => "x" })
  end
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, "hero-settings.json") }

  after { FileUtils.remove_entry(dir) }

  describe ".export" do
    it "writes only the hero content blocks to a JSON file" do
      expect(described_class.export(path)).to eq(1)

      data = JSON.parse(File.read(path))
      expect(data["version"]).to eq(described_class::VERSION)
      expect(data["content_blocks"]).to contain_exactly(
        "id" => hero.id,
        "organization_id" => organization.id,
        "scope_name" => "homepage",
        "settings" => { "welcome_text_en" => "Hello", "cta_button_text_en" => "Old CTA" }
      )
    end

    it "does not overwrite an existing file" do
      File.write(path, "previous")

      expect { described_class.export(path) }.to raise_error(Errno::EEXIST)
      expect(File.read(path)).to eq("previous")
    end
  end

  describe ".restore" do
    before do
      described_class.export(path)
      # Simulates the CTA migration overwriting the settings
      hero.update_columns(settings: { "cta_button_text_en" => "New CTA" })
    end

    it "adds the missing keys and preserves the current values" do
      expect(described_class.restore(path)).to eq(1)

      expect(hero.reload[:settings]).to eq("welcome_text_en" => "Hello", "cta_button_text_en" => "New CTA")
    end

    it "does not touch other content blocks" do
      expect { described_class.restore(path) }.not_to(change { other_block.reload[:settings] })
    end

    context "when a content block in the backup does not exist" do
      let(:missing_id) { hero.id + 1000 }

      before do
        data = JSON.parse(File.read(path))
        data["content_blocks"].unshift(data["content_blocks"].first.merge("id" => missing_id))
        File.write(path, JSON.generate(data))
      end

      it "reports the failure and restores the rest of the blocks" do
        result = nil
        expect { result = described_class.restore(path) }.to output(/Block \[#{missing_id}\] failed/).to_stdout

        expect(result).to eq(1)
        expect(hero.reload[:settings]).to eq("welcome_text_en" => "Hello", "cta_button_text_en" => "New CTA")
      end
    end

    context "when the backup has an invalid format" do
      before { File.write(path, JSON.generate(version: 99, content_blocks: [])) }

      it "raises an error" do
        expect { described_class.restore(path) }.to raise_error(ArgumentError, /format or version/)
      end
    end

    context "when the backup has duplicated ids" do
      before do
        data = JSON.parse(File.read(path))
        data["content_blocks"] += data["content_blocks"]
        File.write(path, JSON.generate(data))
      end

      it "raises an error" do
        expect { described_class.restore(path) }.to raise_error(ArgumentError, /Duplicate/)
      end
    end
  end
end
