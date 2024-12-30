# frozen_string_literal: true

require "decidim/version"
require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :participatory_processes do
    desc <<~EODESC
      Add content blocks to a participatory processes
    EODESC
    task :add_content_blocks, [:content_block_names] => :environment do |_task, args|
      unless Decidim.version >= "0.28"
        puts "This command is only compatible with Decidim v0.28 or higher"
        exit(-1)
      end

      content_block_names = args[:content_block_names].split(' ')

      adder = ::Decidim::Cdtb::ParticipatorySpaces::AddContentBlocks.new(content_block_names)
      adder.execute!
    end
  end
end
