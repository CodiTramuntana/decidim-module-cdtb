# frozen_string_literal: true

#
# A set of utils to migrate from one storage service to another.
#
namespace :cdtb do
  require "decidim/cdtb/tasks_utils"
  include Decidim::Cdtb::TasksUtils
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
      task= Decidim::Cdtb::Storage::LocalSharding.new
      task.execute!
    end

    desc <<~EODESC
      Updates all ActiveStorage::Blob rows in the DB to use the :local service.
    EODESC
    task set_local_service_on_blobs: [:environment] do
      task= Decidim::Cdtb::Storage::SetLocalOnBlobs.new
      task.execute!
    end
  end
end
