# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rake cdtb:s3_to_local:do_sharding" do # , type: :task do
  context "when executing task" do
    context "when there are NO assets" do
      it "have to be executed without failures" do
        expect { task.execute }.not_to raise_error
      end
    end

    context "when there are assets downloaded from S3" do
      let!(:blob) do
        ActiveStorage::Blob.create("id" => 236,
                                   "key" => "otnvxpdbhv9qtrpl2laoe6xlkaoy",
                                   "filename" => "Dummy blob",
                                   "content_type" => "text/plain",
                                   "checksum" => "dtOAyKWWO9fXv9V99twZdg==",
                                   "byte_size" => 0)
      end
      let!(:expected_path) { ActiveStorage::Blob.service.path_for(blob.key) }

      before do
        from_blob_dir= Rails.root.join("tmp/storage/")
        from_blob_path= File.join(from_blob_dir, blob.key)
        FileUtils.touch(from_blob_path)
      end

      after do
        File.delete(expected_path)
      end

      it "moves the file doing sharding" do
        task.execute
        expect(File.exist?(expected_path)).to be_truthy
      end
    end
  end
end
