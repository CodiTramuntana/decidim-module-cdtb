# frozen_string_literal: true

module Decidim
  module Cdtb
    module Storage
      # Updates all ActiveStorage::Blob rows in the DB to use the :local service.
      class SetLocalOnBlobs < ::Decidim::Cdtb::Task
        def initialize
          super("S3 to local: FORCE LOCAL SERVICE")
        end

        def prepare_execution(_ctx)
          @num_blobs= ActiveStorage::Blob.count
          log_task_info("Updating #{@num_blobs} blobs...")
        end

        def total_items
          @num_blobs
        end

        def do_execution(_context)
          ActiveStorage::Blob.update(service_name: "local")
        end

        def end_execution(_ctx)
          log_task_info("Blobs updated")
        end

        #----------------------------------------------------------------

        #----------------------------------------------------------------
      end
    end
  end
end
