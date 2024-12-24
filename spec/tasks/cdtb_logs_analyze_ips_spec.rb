# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rake cdtb:logs:analyze_ips", type: :task do
  context "when executing task" do
    it "have to be executed without failures" do
      args= Rake::TaskArguments.new([:logfile], ["tmp/calafell-num_rq_per_ip.log"])
      # expect { task.execute(args) }.not_to raise_error
      expect { task.execute(args) }.to output("oliver").to_stdout
    end
  end
end
