# frozen_string_literal: true

require "cdtb/ip_parser"

unless ENV["CDTB_RACK_ATTACK_DISABLED"].to_i.positive? || %w[development test].include?(Rails.env)
  require "rack/attack"
  Cdtb::IpParser.decorate_rack_request

  limit= ENV.fetch("RACK_ATTACK_THROTTLE_LIMIT", 30)
  period= ENV.fetch("RACK_ATTACK_THROTTLE_PERIOD", 60)
  Rails.logger.info("Configuring Rack::Attack.throttle with limit for requests by ip: #{limit}, period: #{period}")
  Rack::Attack.throttle("cdtb:requests by ip", limit: limit.to_i, period: period.to_i) do |request|
    # ignore requests to assets
    next if request.path.start_with?("/rails/active_storage")

    Cdtb::IpParser.extract_ip(request)
  end

  if ENV.key?("RACK_ATTACK_THROTTLE_RANGE_LIMIT") && ENV["RACK_ATTACK_THROTTLE_RANGE_LIMIT"].to_i.positive?
    limit= ENV.fetch("RACK_ATTACK_THROTTLE_RANGE_LIMIT", 30)
    period= ENV.fetch("RACK_ATTACK_THROTTLE_RANGE_PERIOD", 60)
    Rails.logger.info("Configuring Rack::Attack.throttle with limit for IP Ranges: #{limit}, period: #{period}")
    Rack::Attack.throttle("cdtb:requests by ip range", limit: limit.to_i, period: period.to_i) do |request|
      # ignore requests to assets
      next if request.path.start_with?("/rails/active_storage")

      ip= Cdtb::IpParser.extract_ip(request)
      # rubocop: disable Lint/UselessAssignment
      range_32bit= ip.split(".")[0, 2]
      # rubocop: enable Lint/UselessAssignment
    end
  end

  Rack::Attack.blocklist("cdtb:block all /.well-known/traffic-advice") do |request|
    request.path.start_with?("/.well-known/traffic-advice")
  end

  Rack::Attack.blocklist("cdtb:block all PHP RQs") do |request|
    request.path.end_with?("*.php")
  end

  if ENV["RACK_ATTACK_BLOCKED_IPS"].present?
    blocked_ips_and_subnets= ENV["RACK_ATTACK_BLOCKED_IPS"].split(",")
    Rack::Attack.blocklist("cdtb:block all unaccepted IPs") do |request|
      ip= Cdtb::IpParser.extract_ip(request)
      blocked_ips_and_subnets.any? { |ip_or_subnet| ip.start_with?(ip_or_subnet) }
    end
  end
end
