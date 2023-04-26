# frozen_string_literal: true

#
# A set of utils to migrate from one storage service to another.
#
namespace :cdtb do
  require_relative "cdtb_tasks_utils"
  include Cdtb::TasksUtils
  require "decidim/cdtb/storage/local_sharding"

  # To migrate from S3 to local storage.
  #
  # Typical use case is:
  # 1. aws s3 sync s3://bucket-name tmp/storage/
  # 2. bin/rake cdtb:s3_to_local:do_sharding
  # 3. rm -Rf tmp/cache/*
  #
  namespace :s3_to_local do
    desc <<~EODESC
      Given that all assets has already been copied from S3 to storage/, this task performs the sharding of the downloaded files.
      This step is required because in S3 all assets are stored at the same level (directory), but local service stores the files with sharding.
    EODESC
    task do_sharding: [:environment] do
      log_task_title("S3 to local: DO SHARDING")
      prepare_task
      local_sharding= Decidim::Cdtb::Storage::LocalSharding.new
      num_blobs= ActiveStorage::Blob.count

      log_task_info("Checking #{num_blobs} blobs...")
      log_start_steps(total: num_blobs, title: "ActiveStorage::Blobs") do |progress_bar|
        local_sharding.perform!(progress_bar)
      end

      log_task_info("#{local_sharding.num_moved} blobs sharded")
      log_task_end
    end

    desc <<~EODESC
      Updates all ActiveStorage::Blob rows in the DB to use the :local service.
    EODESC
    task set_local_service_on_blobs: [:environment] do
      log_task_title("S3 to local: FORCE LOCAL SERVICE")
      prepare_task
      num_blobs= ActiveStorage::Blob.count

      log_task_info("Updating #{num_blobs} blobs...")
      log_start_steps(total: num_blobs, title: "ActiveStorage::Blobs") do |_progress_bar|
        ActiveStorage::Blob.update(service_name: "local")
      end

      log_task_info("Blobs updated")
      log_task_end
    end
  end
end
