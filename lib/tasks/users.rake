# frozen_string_literal: true

require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :users do
    desc <<~EODESC
      Fix Decidim::User's nicknames.
    EODESC
    task fix_nicknames: [:environment] do
      fixer= Decidim::Cdtb::Fixes::NicknameFixer.new
      fixer.execute!
    end

    desc <<~EODESC
      Remove Decidim::User's by IDs in a CSV.
    EODESC
    task :remove, %i[organization_id csv_path reporter_user_email] => [:environment] do |_taks, args|
      service = Decidim::Cdtb::Users::Remover.new(args.organization_id, args.csv_path, args.reporter_user_email)
      service.execute!
    end

    desc <<~EODESC
      Exports the list of admins to a CSV file. If +org_id+ is set, filters by that organization.
    EODESC
    task :list_admins, %i[org_id] => [:environment] do |_taks, args|
      organization_id= args.org_id

      query= Decidim::User.includes(:organization).where(admin: true)
      filename= "admins"

      if organization_id.present?
        query= query.where(organization_id:)
        filename+= "-org#{organization_id}"
      end

      CSV.open("#{filename}.csv", "wb") do |csv|
        csv << ["ID", "Organization ID", "Organization", "Name", "Email", "Created at", "Last sign in at"]

        query.find_each do |admin|
          csv << [
            admin.id,
            admin.organization.id,
            admin.organization.name,
            admin.name,
            admin.email,
            admin.created_at.strftime(Decidim::Cdtb::STRFTIME_FORMAT),
            admin.last_sign_in_at&.strftime(Decidim::Cdtb::STRFTIME_FORMAT)
          ]
        end
      end
    end
  end
end
