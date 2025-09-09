# frozen_string_literal: true

# Used internally by Rack::Request.trusted_proxy?(ip)
if ENV.key?("RACK_RQ_IP_FILTER_EXT") && ENV["RACK_RQ_IP_FILTER_EXT"].present?
  ORIGINAL_REGEX= /\A127\.0\.0\.1\Z|\A(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\.|\A::1\Z|\Afd[0-9a-f]{2}:.+|\Alocalhost\Z|\Aunix\Z|\Aunix:/i
  Rack::Request.ip_filter = lambda do |ip|
    regex_str= ORIGINAL_REGEX.to_s
    regex_str << ENV.fetch("RACK_RQ_IP_FILTER_EXT", nil)
    /#{regex_str}/i.match?(ip)
  end
end
