# frozen_string_literal: true

module Decidim
  module Cdtb
    module Fixes
      # Fixes YouTube embeds to Decidim v0.28 format in PROCESSED_MODELS.
      # Only YouTube is supported right now.
      class YouTubeEmbedsFixer < ::Decidim::Cdtb::Task
        PROCESSED_MODELS= {
          "Decidim::Meetings::Meeting" => [:description],
          "Decidim::Debates::Debate" => %i[description instructions],
          "Decidim::StaticPage" => [:content],
          "Decidim::Pages::Page" => [:body],
          "Decidim::Assembly" => %i[short_description description],
          "Decidim::ParticipatoryProcess" => %i[short_description description]
        }.freeze

        def initialize
          progress_bar= { title: self.class.name }
          super("FIX YOUTUBE EMBEDS", progress_bar:)
        end

        attr_reader :num_fixed

        def prepare_execution(_ctx = nil)
          @num_fixed= @num_items= 0

          PROCESSED_MODELS.each_key do |model_class|
            @num_items+= model_class.constantize.count
          end
          log_task_info("Checking #{@num_items} models...")
        end

        def total_items
          @num_items
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          PROCESSED_MODELS.each_pair do |model_class_name, attribs|
            log_task_step("Processing #{model_class_name.pluralize}")

            model_class= model_class_name.constantize
            model_class.find_each do |model|
              Rails.logger.debug("Processing #{model_class_name}[#{model.id}]")

              attribs.each do |attribute|
                fix_embed(model, attribute)
              end

              @num_fixed+= 1 if model.changed?
              model.save!(validate: false)
              progress_bar.increment
            end
          end
        end

        def end_execution(_ctx)
          log_task_step("#{@num_fixed} embeds fixed")
        end

        # --------------------------------------------------
        private

        # --------------------------------------------------

        def fix_embed(model, attribute)
          contents= model.send(attribute)
          return if contents.blank?

          contents.each_pair do |locale, content|
            Rails.logger.debug "#{locale} => #{content}"
            next if locale.to_s == "machine_translations"
            next if content.blank?

            fixes= fix_localized_embed(content)
            contents[locale]= fixes.reverse.find { |fix| fix != false } if fixes.any?
          end
        end

        # rubocop: disable Metrics/AbcSize
        def fix_localized_embed(content)
          parsed= Nokogiri::HTML(content)
          divs_w_embed= parsed.css("div[class=editor-content-videoEmbed]")
          Rails.logger.debug "=> #{divs_w_embed.size} => #{content}"

          divs_w_embed.map do |div|
            iframe= div.css("iframe").first

            regexp_match= if div["data-video-embed"].present?
                            find_localized_embed_from_video_btn(div)
                          else
                            find_localized_embed_from_embed_btn(iframe)
                          end

            next unless regexp_match

            Rails.logger.debug("EMBED:::: #{div.class} => #{div}")

            yt_id= regexp_match["yt_id"]
            div["data-video-embed"]= "https://www.youtube.com/watch?v=#{yt_id}"
            iframe["src"]= "https://www.youtube-nocookie.com/embed/#{yt_id}?cc_load_policy=1&modestbranding=1"
            fixed_div= div
            Rails.logger.debug("FIXED TO: #{fixed_div.to_html}")
            new_content= parsed.css("body").children.to_html
            Rails.logger.debug("FIXED TO: #{new_content}")
            new_content
          end.compact
        end
        # rubocop: enable Metrics/AbcSize

        def find_localized_embed_from_video_btn(div)
          div["data-video-embed"].match(%r{https://www.youtube.com/embed/(?<yt_id>\w+)})
        end

        def find_localized_embed_from_embed_btn(iframe)
          iframe["src"].match(%r{https://www.youtube.com/embed/(?<yt_id>\w+)})
        end
      end
    end
  end
end
