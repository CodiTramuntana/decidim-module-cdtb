# frozen_string_literal: true

namespace :cdtb do
  namespace :spam do
    desc "Show a list with users suspected of spam"
    task :users, %i[host] => :environment do |_task, args|
      detector = ::Decidim::Cdtb::Spam::UserSpamDetector.new(args.host)
      detector.execute!
    end
  end
end
