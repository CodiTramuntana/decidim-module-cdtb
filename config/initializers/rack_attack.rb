# frozen_string_literal: true

unless ENV["CDTB_RACK_ATTACK_DISABLED"].to_i.positive? || %w[development test].include?(Rails.env)
  require "rack/attack"

  def extract_ip(request)
    x_forwarded_for= request.get_header("HTTP_X_FORWARDED_FOR")
    Rails.logger.info { ">>>>>>>>>>>>>>>>>>>> X-Forwarded-For: #{x_forwarded_for}" }
    if x_forwarded_for.present?
      x_forwarded_for.split(":").first

    else
      request.ip
    end
  end

  limit= ENV.fetch("RACK_ATTACK_THROTTLE_LIMIT", 30)
  period= ENV.fetch("RACK_ATTACK_THROTTLE_PERIOD", 60)
  Rails.logger.info("Configuring Rack::Attack.throttle with limit: #{limit}, period: #{period}")
  Rack::Attack.throttle("requests by ip", limit: limit.to_i, period: period.to_i) do |request|
    # ignore requests to assets
    next if request.path.start_with?("/rails/active_storage")

    extract_ip(request)
  end

  limit= ENV.fetch("RACK_ATTACK_THROTTLE_RANGE_LIMIT", 10)
  period= ENV.fetch("RACK_ATTACK_THROTTLE_RANGE_PERIOD", 20)
  Rails.logger.info("Configuring Rack::Attack.throttle with limits for IP Ranges: #{limit}, period: #{period}")
  Rack::Attack.throttle("requests by ip range", limit: limit.to_i, period: period.to_i) do |request|
    # ignore requests to assets
    next if request.path.start_with?("/rails/active_storage")

    ip= extract_ip(request)
    # rubocop: disable Lint/UselessAssignment
    range_32bit= ip.split(".")[0, 2]
    # rubocop: enable Lint/UselessAssignment
  end

  Rack::Attack.blocklist("block all /.well-known/traffic-advice") do |request|
    request.path.start_with?("/.well-known/traffic-advice")
  end

  if ENV["RACK_ATTACK_BLOCKED_IPS"].present?
    blocked_ips_and_subnets= ENV["RACK_ATTACK_BLOCKED_IPS"].split(",")
    Rack::Attack.blocklist("block all unaccepted IPs") do |request|
      ip= extract_ip(request)
      blocked_ips_and_subnets.any? { |ip_or_subnet| ip.start_with?(ip_or_subnet) }
    end
  end
end
