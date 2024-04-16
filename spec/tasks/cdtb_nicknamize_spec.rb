# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rake cdtb:users:fix_nicknames", type: :task do
  let!(:user) { create(:user) }

  context "when executing task" do
    it "have to be executed without failures" do
      expect { task.execute }.not_to raise_error
    end

    context "when the nickname is already valid" do
      it "do not enqueues any job" do
        expect { task.execute }.not_to have_enqueued_job(Cdtb::FixNicknameJob)
      end
    end

    context "when the nickname is invalid" do
      setup do
        user.update_attribute :nickname, "bad nickname!"
      end

      it "enqueues the job" do
        expect { task.execute }.to have_enqueued_job(Cdtb::FixNicknameJob)
      end
    end
  end
end
