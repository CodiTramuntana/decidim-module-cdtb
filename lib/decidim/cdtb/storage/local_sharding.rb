# frozen_string_literal: true

module Decidim
  module Cdtb
    module Storage
      # Given that all assets has already been copied from S3 to storage/,
      # this task performs the sharding of the downloaded files.
      #
      # This step is required because in S3 all assets are stored flat at the same level (directory),
      # but local service stores the files with sharding.
      class LocalSharding
        def initialize
          @num_moved = 0
        end

        attr_reader :num_moved

        def perform!(progress_bar)
          ActiveStorage::Blob.find_each do |blob|
            path= ActiveStorage::Blob.service.path_for(blob.key)
            src_file= Rails.root.join("tmp/storage", blob.key)
            if File.exist?(src_file)
              shard_asset(blob, path)
              @num_moved+= 1
            else
              logger.warn "File Not Found or directory: #{path}"
            end
            progress_bar.increment
          end
        end

        #----------------------------------------------------------------

        private

        #----------------------------------------------------------------

        def shard_asset(blob, path)
          blob_dir= File.dirname path
          logger.info "Creating dir: #{blob_dir}"
          FileUtils.mkdir_p(blob_dir)
          FileUtils.mv Rails.root.join("tmp/storage", blob.key), path, force: true
          logger.info "Sharding for file: #{path}"
        end
      end
    end
  end
end
