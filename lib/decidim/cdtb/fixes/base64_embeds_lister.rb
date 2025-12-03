# frozen_string_literal: true

require "csv"

module Decidim
  module Cdtb
    module Fixes
      # Lists Base64 embeds to Decidim v0.28 format in Decidim::Cdtb::Embeds::PROCESSED_MODELS.
      class Base64EmbedsLister < ::Decidim::Cdtb::Task
        def initialize
          progress_bar= { title: self.class.name }
          super("LIST Base64 EMBEDS", progress_bar:)
        end

        def prepare_execution(_ctx = nil)
          @num_items= 0
          @matches= {}

          Decidim::Cdtb::Embeds::PROCESSED_MODELS.each_key do |model_class|
            @num_items+= model_class.constantize.count
            @num_items+= PaperTrail::Version.where(item_type: model_class).count
          end
          log_task_info("Checking #{@num_items} models...")
        end

        def total_items
          @num_items
        end

        def do_execution(context)
          progress_bar= context[:progress_bar]

          Decidim::Cdtb::Embeds::PROCESSED_MODELS.each_pair do |model_class_name, attribs|
            progress_bar.title= model_class_name

            model_class= model_class_name.constantize
            model_class.find_each do |model|
              progress_bar.increment
              # print('*')
              find_matches_in_model(model, attribs)
            end
            PaperTrail::Version.where(item_type: model_class_name).find_each do |version|
              progress_bar.increment
              find_matches_in_papertrail(version, attribs)
            end
          end
        end

        # rubocop: disable Metrics/AbcSize
        def end_execution(_ctx)
          puts ""
          log_task_step("#{@matches.values.flatten.count} models with base64 embeds found. CSV:")
          puts ""
          headers= ["id organization", "id model_class#field", "slug", "URL", "KBytes", "created_at ",
                    "model published?", "component published?", "space published?"]

          output_string = CSV.generate do |csv|
            csv << headers

            @matches.each_pair do |model, matchings|
              matchings.each do |matching|
                infos= if model.is_a?(PaperTrail::Version)
                         to_papertrail_infos(model, matching)
                       else
                         to_model_infos(model, matching)
                       end
                csv << infos
              end
            end
          end

          puts output_string
          puts ""
        end
        # rubocop: enable Metrics/AbcSize

        # --------------------------------------------------

        private

        # --------------------------------------------------

        def find_matches_in_model(model, attribs)
          attribs.each do |attrib|
            # print('·')
            content= model.send(attrib)
            next unless content.present?

            Decidim.available_locales.find do |locale|
              # print('_')
              if content[locale]&.match?(Decidim::Cdtb::Embeds::EMBEDED_IMG_BASE64_REGEX)
                @matches[model]= [] unless @matches[model].present?
                @matches[model] << { id: model.id, attrib: }
                true
              else
                false
              end
            end
          end
        end

        # rubocop: disable Metrics/AbcSize
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def find_matches_in_papertrail(version, attribs)
          model= version.object
          changes= version.object_changes
          return unless model || changes.present?

          attribs.each do |attrib|
            contents= []
            if model && model[attrib.to_s].present?
              Decidim.available_locales.find do |locale|
                contents << model[attrib.to_s]&.fetch(locale, nil)
              end
            end
            contents << changes if changes.present?
            next unless contents.compact.any?

            if contents.any? { |content| content&.match?(Decidim::Cdtb::Embeds::EMBEDED_IMG_BASE64_REGEX) }
              @matches[version]= [] unless @matches[version].present?
              @matches[version] << { id: version.id, item_type: version.item_type, item_id: version.item_id, attrib: }
              true
            else
              false
            end
          end
        end

        # rubocop: enable Metrics/PerceivedComplexity
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/AbcSize

        # rubocop: disable Metrics/AbcSize
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        BYTES_IN_KB= 1024
        def to_model_infos(model, matching)
          infos= [
            "[#{model.try(:organization)&.id}] #{model.try(:organization)&.host}",
            "[#{model.id}]#{model.class.name}##{matching[:attrib]} ",
            model.respond_to?(:slug) ? model.slug : "n/a",
            model_url(model),
            model.send(matching[:attrib]).to_s.bytesize / BYTES_IN_KB,
            model.created_at.to_date.to_s,
            (if model.respond_to?(:published?)
               model.published? ? "published" : "unpublished"
             else
               "n/a"
             end)
          ]

          if model.respond_to?(:component)
            component= model.component
            infos << (component.published? ? "published" : "unpublished")
            infos << (component.participatory_space.published? ? "published" : "unpublished")
          end
          infos
        end
        # rubocop: enable Metrics/PerceivedComplexity
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/AbcSize

        # rubocop: disable Metrics/AbcSize
        # rubocop: disable Metrics/PerceivedComplexity
        def to_papertrail_infos(version, matching)
          item= version.item
          if item
            infos= to_model_infos(item, matching)
            infos[0]= "VERSION-#{infos[0]}"
            infos
          else
            [
              "[#{version.try(:organization)&.id}] #{version.try(:organization)&.host}",
              "[#{version.id}]#{version.class.name}/#{version.item_type}##{matching[:attrib]} ",
              version["slug"] ? version.slug : "n/a",
              "n/a",
              version[matching[:attrib].to_s].to_s.bytesize,
              version.created_at.to_date.to_s,
              (if version.respond_to?(:published?)
                 version.published? ? "published" : "unpublished"
               else
                 "n/a"
               end)
            ]
          end
        end
        # rubocop: enable Metrics/AbcSize
        # rubocop: enable Metrics/PerceivedComplexity

        # rubocop: disable Metrics/AbcSize
        def model_url(model)
          if model.is_a?(Decidim::ParticipatorySpaceResourceable)
            url= "https://#{model.organization.host}"
            url+= space_path(model)
            return url
          elsif model.is_a?(Decidim::StaticPage)
            url= "https://#{model.organization.host}/#{model.slug}"
            return url
          end

          component= model.component
          space= component.participatory_space
          organization= space.organization

          url= "https://#{organization.host}#{space_path(space)}/f/#{component.id}"
          model_path= "/#{model.class.name.demodulize.pluralize.downcase}"
          "#{url}#{model_path}/#{model.id}"
        end
        # rubocop: enable Metrics/AbcSize

        def space_path(space)
          url= case space
               when Decidim::Assembly
                 "/assemblies/"
               when Decidim::ParticipatoryProcess
                 "/processes/"
               when Decidim::Conference
                 "/conferences/"
               when Decidim::Initiative
                 "/initiatives/"
               end
          url + space.slug
        end
      end
    end
  end
end
