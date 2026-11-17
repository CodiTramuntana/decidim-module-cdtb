# frozen_string_literal: true

require "json"

module Decidim
  module Cdtb
    module Upgrades
      # Exports and restores the raw settings of every hero content block.
      #
      # The `MoveCtaToHeroContentBlock` migration from Decidim v0.31 overwrites the hero
      # content block settings with only the CTA values, losing every other setting.
      # Export the settings before migrating and restore them afterwards.
      module HeroContentBlockSettings
        VERSION = 1

        # Writes a versioned JSON file with the settings of all hero content blocks.
        # Refuses to overwrite an existing file and makes it readable only by the owner.
        #
        # Returns the number of exported content blocks.
        def self.export(path)
          records = Decidim::ContentBlock.where(manifest_name: "hero").order(:id)
                                         .pluck(:id, :decidim_organization_id, :scope_name, :settings)
                                         .map do |id, organization_id, scope_name, settings|
            { id:, organization_id:, scope_name:, settings: }
          end

          File.open(path, "wx", 0o600) do |file|
            file.write(JSON.pretty_generate(version: VERSION, content_blocks: records))
            file.write("\n")
          end
          records.size
        end

        # Restores the keys missing from the current settings of each hero content block.
        # Current values (including the migrated CTA values) are always preserved.
        # Everything is restored in one transaction: any invalid record aborts the restore.
        #
        # Returns the number of processed content blocks.
        def self.restore(path)
          backup = JSON.parse(File.read(path))
          records = validate_backup!(backup)

          Decidim::ContentBlock.transaction do
            records.each { |record| restore_record!(record) }
          end
          records.size
        end

        def self.restore_record!(record)
          block = Decidim::ContentBlock.lock.find_by!(
            id: record.fetch("id"),
            decidim_organization_id: record.fetch("organization_id"),
            scope_name: record.fetch("scope_name"),
            manifest_name: "hero"
          )
          current = block[:settings]
          raise ArgumentError, "Invalid current settings for hero block #{block.id}" unless current.nil? || current.is_a?(Hash)

          current ||= {}
          restored = (record.fetch("settings") || {}).merge(current)
          return if restored == current

          block.update_columns(settings: restored, updated_at: Time.current)
        end

        def self.validate_backup!(backup)
          raise ArgumentError, "Invalid hero settings backup format or version" unless valid_format?(backup)

          records = backup.fetch("content_blocks")
          raise ArgumentError, "Invalid hero settings backup record" unless records.all? { |record| valid_record?(record) }

          ids = records.map { |record| record.fetch("id") }
          raise ArgumentError, "Duplicate hero content block IDs in backup" unless ids.uniq.size == ids.size

          records
        end

        def self.valid_format?(backup)
          backup.is_a?(Hash) && backup["version"] == VERSION && backup["content_blocks"].is_a?(Array)
        end

        def self.valid_record?(record)
          record.is_a?(Hash) &&
            positive_integer?(record["id"]) &&
            positive_integer?(record["organization_id"]) &&
            record["scope_name"].is_a?(String) && !record["scope_name"].empty? &&
            valid_settings?(record)
        end

        def self.valid_settings?(record)
          record.key?("settings") && (record["settings"].nil? || record["settings"].is_a?(Hash))
        end

        def self.positive_integer?(value)
          value.is_a?(Integer) && value.positive?
        end
        private_class_method :restore_record!, :validate_backup!, :valid_format?, :valid_record?, :valid_settings?, :positive_integer?
      end
    end
  end
end
