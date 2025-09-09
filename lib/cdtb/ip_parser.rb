# frozen_string_literal: true

module Cdtb
  # Parses IPs from Rack::Request objects, discarding the port.
  module IpParser
    def self.extract_ip(request)
      # take the IP either from the remote addr or from the forwarded for header
      ip= request.ip
      Rails.logger.info { ">>>>>>>>>>>>>>>>>>>> Request IP: #{ip}" }
      Rails.logger.info { ">>>>>>>>>>>>>>>>>>>> X-Forwarded-For: #{request.get_header("HTTP_X_FORWARDED_FOR")}" }

      num_colons= ip.scan(":").length
      if [1, 6].include?(num_colons)
        # is an IP (v4 or v6) with port
        ip.rpartition(":").first
      else
        # standard inet4 or inet6 IP without port
        ip
      end
    end

    def extract_ip(request)
      ::Cdtb::IpParser.extract_ip(request)
    end
  end
end
