# frozen_string_literal: true

require "decidim/version"
require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :participatory_spaces do
    desc <<~EODESC
      Add content blocks to a participatory processes
    EODESC
    task :add_content_blocks, [:content_block_names] => :environment do |_task, args|
      unless Decidim.version >= "0.28"
        puts "This command is only compatible with Decidim v0.28 or higher"
        exit(-1)
      end

      content_block_names = args[:content_block_names].split

      puts "\n Select participatory spaces you want to add the content blocks: #{content_block_names}"
      puts "\n 1. Decidim::ParticipatoryProcess"
      puts "\n 2. Decidim::Assembly"
      puts "\n 3. All"

      selected_option = $stdin.gets.chomp
      puts selected_option

      case selected_option
      when "1"
        processed_models = [
          Decidim::ParticipatoryProcess
        ].freeze
      when "2"
        processed_models = [
          Decidim::Assembly
        ].freeze
      when "3"
        processed_models = [
          Decidim::ParticipatoryProcess,
          Decidim::Assembly
        ].freeze
      else
        return "Please, select an option"
      end

      adder = Decidim::Cdtb::ParticipatorySpaces::AddContentBlocks.new(processed_models, content_block_names)
      adder.execute!
    end

    desc <<~EODESC
      Move images to content block for the participatory spaces
    EODESC
    task move_images_to_content_block: :environment do
      unless Decidim.version >= "0.28"
        puts "This command is only compatible with Decidim v0.28 or higher"
        exit(-1)
      end

      puts "\n Select participatory spaces you want to move the images"
      puts "\n 1. Decidim::ParticipatoryProcess"
      puts "\n 2. Decidim::Assembly"
      puts "\n 3. All"

      selected_option = $stdin.gets.chomp
      puts selected_option

      case selected_option
      when "1"
        processed_models = [
          Decidim::ParticipatoryProcess
        ].freeze
      when "2"
        processed_models = [
          Decidim::Assembly
        ].freeze
      when "3"
        processed_models = [
          Decidim::ParticipatoryProcess,
          Decidim::Assembly
        ].freeze
      else
        return "Please, select an option"
      end

      adder = Decidim::Cdtb::ParticipatorySpaces::MoveImagesToContentBlock.new(processed_models)
      adder.execute!
    end
  end
end
