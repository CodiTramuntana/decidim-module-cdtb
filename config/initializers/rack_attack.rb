# frozen_string_literal: true

unless ENV["CDTB_RACK_ATTACK_DISABLED"].to_i.positive? || %w[development test].include?(Rails.env)
  require "rack/attack"

  limit= ENV["RACK_ATTACK_THROTTLE_LIMIT"] || 30
  period= ENV["RACK_ATTACK_THROTTLE_PERIOD"] || 60
  Rails.logger.info("Configuring Rack::Attack.throttle with limit: #{limit}, period: #{period}")
  Rack::Attack.throttle("requests by (forwarded) ip", limit: limit.to_i, period: period.to_i) do |request|
    # ignore requests to assets
    next if request.path.start_with?("/rails/active_storage")

    x_forwarded_for= request.get_header("HTTP_X_FORWARDED_FOR")
    Rails.logger.info { ">>>>>>>>>>>>>>>>>>>> X-Forwarded-For: #{x_forwarded_for}" }
    if x_forwarded_for.present?
      ip= x_forwarded_for.split(":").first
      ip
    else
      request.ip
    end
  end

  if ENV["RACK_ATTACK_BLOCKED_IPS"].present?
    ENV["RACK_ATTACK_BLOCKED_IPS"].split(",").each do |ip_or_subnet|
      Rack::Attack.blocklist_ip(ip_or_subnet)
    end
  end
end
