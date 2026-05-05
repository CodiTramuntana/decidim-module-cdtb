# frozen_string_literal: true

module Cdtb
  # Parses IPs from Rack::Request objects, discarding the port.
  module IpParser
    def self.decorate_rack_request
      Rack::Request.class_eval do
        include Cdtb::IpParser

        alias_method :original_ip_method, :ip

        def ip
          extract_ip(self)
        end
      end
    end

    def self.extract_ip(request)
      # Take the IP either from the remote addr or from the forwarded for header
      # If Rack::Request is decorated use the original method.
      ip= defined?(request.original_ip_method) ? request.original_ip_method : request.ip
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
