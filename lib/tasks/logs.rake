# frozen_string_literal: true

namespace :cdtb do
  namespace :logs do
    desc "Analize logs in Rails format. Counts the number of requests for each IP in the logs. Accepts a logfile param, it must be in log/."
    task :num_rq_per_ip, [:logfile] do |_task, args|
      logfile= args.logfile || "development.log"

      file_path= "log/#{logfile}"
      first_cmd= "grep Started"
      piped_cmds= [%(grep " for "), "cut -d ' ' -f13", "sort", "uniq -c", "sort"].join(" | ")
      puts "Running: `#{first_cmd} #{file_path} | #{piped_cmds}`"
      puts `#{first_cmd} #{file_path} | #{piped_cmds}`
    end
  end
end
