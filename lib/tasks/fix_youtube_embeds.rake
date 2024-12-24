# frozen_string_literal: true

require "decidim/version"
require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :embeds do
    desc <<~EODESC
      Fix YouTube embeds to Decidim v0.28 format.
      Only youtube is supported right now.
    EODESC
    task fix_youtube: [:environment] do
      unless Decidim.version >= "0.28"
        puts "This command is only compatible with Decidim v0.28 or higher"
        exit(-1)
      end

      fixer= ::Decidim::Cdtb::Fixes::YouTubeEmbedsFixer.new
      fixer.execute!
    end
  end
end
