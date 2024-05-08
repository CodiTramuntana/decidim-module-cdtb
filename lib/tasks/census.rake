# frozen_string_literal: true

require "decidim/cdtb/tasks"

namespace :cdtb do
  namespace :verifications do
    desc <<~EODESC
      Lists the verifications handlers in the current Decidim application.
    EODESC
    task handlers: :environment do |_task, _args|
      puts "Verification Handlers in this Decidim application:"
      Decidim.authorization_handlers.each do |manifest|
        attrs= if manifest.form.present?
                 manifest.form.constantize.attribute_set.to_a.map(&:name).excluding(:id, :user, :handler_name).join(", ")
               else
                 "No form."
               end
        puts "- #{manifest.name}: (#{attrs})"
      end
    end

    desc <<~EODESC
            Returns the unique_id version of the given arguments for the given authorization handler.
            Params:
              - handler_name
              - (optional) organization_id
              - credential_1,  credential_2, ...: in the form "id_document:00000000T", "birthdate:24/03/1977".
            For example:
            `bin/rake cdtb:verifications:to_unique_id[file_authorization_handler,id_document:00000000T,birthdate:01/01/2000]
      `
    EODESC
    task :to_unique_id, [:handler_name] => :environment do |_task, args|
      puts "Resolving #{args.handler_name} form class"
      handler= find_handler_by_name(args.handler_name)
      puts "Found handler with form class: #{handler.class}"

      fill_handler_args(handler, args)

      puts "unique_id: #{handler.unique_id}"
    end

    def find_handler_by_name(handler_name)
      handler_class= Decidim::Verifications.find_workflow_manifest(handler_name).form
      handler_class.constantize.new
    end

    def fill_handler_args(handler, args)
      arguments= args.to_a[1..]
      current_organization= if !arguments.first.include?(":")
                              Decidim::Organization.find(arguments.first)
                            else
                              Decidim::Organization.first
                            end
      handler.with_context(current_organization: current_organization)

      credentials= arguments.map { |arg| arg.split(":") }
      puts "Setting credentials: #{credentials}"
      credentials.each do |attr, val|
        handler.send("#{attr}=".to_sym, val)
      end
    end

    desc <<~EODESC
      Checks the given credentials against the specified verification handler. Params [handler_name,credential1,credential2,...]"
    EODESC
    task :census_check, [:handler_name] => :environment do |_task, args|
      handler= find_handler_by_name(args.handler_name)
      fill_handler_args(handler, args)
      raise "This handler does not support Cdtb's verification_service" unless handler.respond_to?(:verification_service)

      service= handler.verification_service
      puts "Invoking #{service.class.name}..."
      rs= service.send_request
      puts "Response Ok?: #{service.rs_ok?}"
      puts "RS: #{rs.body}"
    end
  end
end
