# frozen_string_literal: true

require "spec_helper"
require "decidim/meetings/test/factories"
require "decidim/debates/test/factories"
require "decidim/assemblies/test/factories"
require "decidim/participatory_processes/test/factories"

RSpec.describe ::Decidim::Cdtb::Fixes::YouTubeEmbedsFixer do
  subject { described_class.new }

  describe "#prepare_execution" do
    context "with one model of each class" do
      let!(:meeting) { create(:meeting) }
      let!(:debate) { create(:debate) }
      let!(:page) do
        Decidim::Pages::Page.create!(
          body: Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title },
          component: create(:component, manifest_name: "pages")
        )
      end
      let!(:assembly) { create(:assembly) }

      it "returns the total of models to be processed" do
        subject.prepare_execution

        # one for each model plus one process for each component
        expect(subject.total_items).to be 7
      end

      context "when none contains embeds" do
        it "does not fix anything" do
          subject.execute!
          expect(subject.num_fixed).to be 0
        end
      end

      context "when all contain embeds" do
        before do
          [meeting, debate, page, assembly].each do |model|
            old_format_embed= <<~EOEMBED
              <div class="editor-content-videoEmbed" data-video-embed="https://www.youtube.com/embed/GH#{model.id}pRgZcHB1g?showinfo=0">
                <div>
                  <iframe src="https://www.youtube.com/embed/GH#{model.id}pRgZcHB1g?showinfo=0" title="" frameborder="0" allowfullscreen="true">
                  </iframe>
                </div>
              </div>
            EOEMBED
            attribs= described_class::PROCESSED_MODELS[model.class.name]
            attribs.each do |attrib|
              i18n_content= model.send(attrib)
              i18n_content["ca"]= "#{i18n_content["ca"]}#{old_format_embed}"
            end
            model.save!(validate: false)
          end
        end

        it "does fix all models" do
          subject.execute!
          expect(subject.num_fixed).to be 4
          [meeting, debate, page, assembly].each do |model|
            attribs= described_class::PROCESSED_MODELS[model.class.name]
            attribs.each do |attrib|
              i18n_content= model.reload.send(attrib)
              expect(i18n_content["ca"]).to_not include("https://www.youtube.com/embed")
              expect(i18n_content["ca"]).to include("https://www.youtube.com/watch")
              expect(i18n_content["ca"]).to include("https://www.youtube-nocookie.com/embed")
            end
          end
        end
      end
    end
  end
end
