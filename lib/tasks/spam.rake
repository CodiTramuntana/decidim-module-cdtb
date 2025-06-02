# frozen_string_literal: true

namespace :cdtb do
  namespace :spam do
    desc "Show a list with users suspicious of being spammers"
    task :users, %i[org_id] => :environment do |_task, args|
      organization = args.org_id.present? ? Decidim::Organization.find(args.org_id) : nil

      detector = Decidim::Cdtb::Spam::SpamUsersDetector.new(organization)
      detector.execute!
    end
  end
end
