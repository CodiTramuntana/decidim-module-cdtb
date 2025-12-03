# frozen_string_literal: true

module Decidim
  module Cdtb
    # Embed related utils to fix rich text editors.
    #
    module Embeds
      PROCESSED_MODELS= {
        "Decidim::Accountability::Result" => [:description],
        "Decidim::Meetings::Meeting" => [:description],
        "Decidim::Debates::Debate" => %i[description instructions],
        "Decidim::StaticPage" => [:content],
        "Decidim::Pages::Page" => [:body],
        "Decidim::Assembly" => %i[short_description description],
        "Decidim::ParticipatoryProcess" => %i[short_description description],
        "Decidim::Proposals::Proposal" => %i[body]
      }.freeze

      EMBEDED_IMG_BASE64_REGEX= %r{<img [^>]*src=["']data:image/[^;]+;base64}i
    end
  end
end
