# frozen_string_literal: true

namespace :cdtb do
  namespace :logs do
    desc "Analize logs in Rails format. Counts the number of requests for each IP in the logs. Accepts a log path param."
    task :num_rq_per_ip, [:logfile] do |_task, args|
      file_path= args.logfile || "log/production.log"

      first_cmd= "grep Started"
      piped_cmds= [%(grep " for "), "cut -d ' ' -f13", "sort", "uniq -c", "sort"].join(" | ")
      cmd= "#{first_cmd} #{file_path} | #{piped_cmds}"

      puts "Running: `#{cmd}`"
      puts `#{cmd}`
    end

    desc "Analize logs in Rails format. Counts the number of requests for each IP range in the logs. Accepts a log path param."
    task :num_rq_per_ip_range, [:logfile] do |_task, args|
      file_path= args.logfile || "log/production.log"

      first_cmd= "grep Started"
      piped_cmds= [
        %(grep " for "),
        # take the IP
        "cut -d ' ' -f13",
        # trim blank spaces
        "awk '{$1=$1;print}'",
        # range: only the first 2 blocks of the IP
        "cut -d '.' -f1,2",
        "sort",
        "uniq -c",
        "sort"
      ].join(" | ")
      cmd= "#{first_cmd} #{file_path} | #{piped_cmds}"

      puts "Running: `#{cmd}`"
      puts `#{cmd}`
    end

    desc 'Returns the duration, the order in the logs, and the timestamp of each "Completed" trace.'
    task :slow_rq, [:logfile] do |_task, args|
      # Based on the follwoing example execution:
      # grep -e "Completed 200 OK in" log/development.log | ruby logparser.rb | sort

      file_path= args.logfile || "log/production.log"

      idx= 0
      File.open(file_path).each_line do |line|
        idx += 1
        next unless line.include?("Completed 200 OK in")

        split= line.split("Completed 200 OK in")
        second_part= split.last.strip
        words= second_part.split
        response_duration= words.first
        puts "#{response_duration.rjust(7, "0")}, #{idx}, #{line[4, 22]}"
      end
    end

    desc "Most requested paths. Accepts a log path param, and an only_path to ignore the query part of the URL."
    task :most_rq_paths, [:logfile, :only_path] do |_task, args|
      file_path= args.logfile || "log/production.log"

      first_cmd= "grep Started"
      piped_cmds= ["cut -d ' ' -f11"]
      piped_cmds << "cut -d '?' -f 1" if args.only_path == "only_path"
      piped_cmds+= ["sort", "uniq -c", "sort"]
      cmd= "#{first_cmd} #{file_path} | #{piped_cmds.join(" | ")}"

      puts "Running: `#{cmd}`"
      puts `#{cmd}`
    end

    desc "Analizes output from num_rq_per_ip. Finds the country from each IP in the log file. Accepts a log path param."
    task :geolocate_ips, [:logfile] do |_task, args|
      file_path= args.logfile || "log/num_rq_per_ip.log"

      cmd= [
        # strip spaces
        "awk '{$1=$1;print}' #{file_path}",
        "cut -d ' ' -f2",
        "sort"
      ].join(" | ")

      cmd_out= `#{cmd}`
      cmd_out.each_line do |ip|
        ip= ip.strip
        locations= Geocoder.search(ip)
        location_rs= locations.first
        country= parse_nominatim_result(location_rs) || parse_ipinfoio_result(location_rs) || "N/F"
        puts "#{ip},#{country}"
      end
    end

    def parse_nominatim_result(result)
      result&.dig("address", "country")
    end

    def parse_ipinfoio_result(result)
      result&.dig("country")
    end

    desc "Lists from the output of geolocated_ips. Finds the country from each IP in the csv file. Accepts a file path param."
    task :bannable_ips, [:path, :countries] do |_task, args|
      file_path= args.path || "tmp/geolocated_ips.csv"
      countries= args.countries || %w[FR GB IT PT]

      cmd= ["grep -v ES #{file_path}"]
      countries.each do |country_iso|
        cmd << "grep -v #{country_iso}"
      end
      cmd << "cut -d ',' -f1"
      cmd << "sort"

      puts `#{cmd.join(" | ")}`
    end
  end
end
