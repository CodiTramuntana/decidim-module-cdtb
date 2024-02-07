# frozen_string_literal: true

namespace :cdtb do
  namespace :spam do
    desc "Show a list with users suspected of spam"
    task :users, %i[org_id] => :environment do |_task, args|
      organization = args.org_id.present? ? Decidim::Organization.find(args.org_id) : nil

      detector = ::Decidim::Cdtb::Spam::UserSpamDetector.new(organization)
      detector.execute!
    end
  end
end
