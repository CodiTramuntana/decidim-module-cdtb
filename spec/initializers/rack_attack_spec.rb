# frozen_string_literal: true

require "spec_helper"
require "rack/attack"

RSpec.describe "CDTB Rack::Attack initializer" do
  let(:app) do
    Rack::Attack.new(->(_env) { [200, { "content-type" => "text/plain" }, ["OK"]] })
  end

  before(:context) do
    @original_enabled = Rack::Attack.enabled
    @original_cache_store = Rack::Attack.cache.store
    @original_env = %w[
      RACK_ATTACK_THROTTLE_LIMIT
      RACK_ATTACK_THROTTLE_PERIOD
      RACK_ATTACK_THROTTLE_RANGE_LIMIT
      RACK_ATTACK_THROTTLE_RANGE_PERIOD
      RACK_ATTACK_BLOCKED_IPS
      ABUSE_REPORTED_IPS_CSV_PATH
    ].to_h { |key| [key, ENV.fetch(key, nil)] }

    ENV["RACK_ATTACK_THROTTLE_LIMIT"] = "2"
    ENV["RACK_ATTACK_THROTTLE_PERIOD"] = "60"
    ENV["RACK_ATTACK_THROTTLE_RANGE_LIMIT"] = "2"
    ENV["RACK_ATTACK_THROTTLE_RANGE_PERIOD"] = "60"
    ENV["RACK_ATTACK_BLOCKED_IPS"] = "198.51.100.0/24"
    ENV["ABUSE_REPORTED_IPS_CSV_PATH"] = File.expand_path("../fixtures/abuse_reported_ips.csv", __dir__)

    rails_singleton = Rails.singleton_class
    rails_singleton.alias_method :rack_attack_spec_original_env, :env
    rails_singleton.define_method(:env) { "production" }
    begin
      load File.expand_path("../../config/initializers/cdtb_rack_attack.rb", __dir__)
    ensure
      rails_singleton.alias_method :env, :rack_attack_spec_original_env
      rails_singleton.remove_method :rack_attack_spec_original_env
    end

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  after(:context) do
    %w[
      cdtb:requests by ip
      cdtb:requests by ip range
    ].each { |name| Rack::Attack.throttles.delete(name) }
    %w[
      cdtb:block all /.well-known/traffic-advice
      cdtb:block all PHP RQs
      block IPs in reported website
      cdtb:block all unaccepted IPs
    ].each { |name| Rack::Attack.blocklists.delete(name) }

    Rack::Attack.cache.store.clear
    Rack::Attack.cache.store = @original_cache_store
    Rack::Attack.enabled = @original_enabled
    @original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  before do
    Rack::Attack.cache.store.clear
  end

  def request_status(path, ip)
    env = Rack::MockRequest.env_for(path, "REMOTE_ADDR" => ip)
    app.call(env).first
  end

  describe "blocklists" do
    it "blocks traffic-advice requests" do
      expect(request_status("/.well-known/traffic-advice", "203.0.113.1")).to eq(403)
    end

    it "blocks PHP paths" do
      expect(request_status("/wp-login.php", "203.0.113.1")).to eq(403)
    end

    it "blocks an IP inside a configured CIDR and allows an IP outside it" do
      expect(request_status("/", "198.51.100.24")).to eq(403)
      expect(request_status("/", "198.51.101.24")).to eq(200)
    end

    it "blocks IPs listed in the abuse-report CSV" do
      expect(request_status("/", "203.0.113.55")).to eq(403)
      expect(request_status("/", "203.0.113.56")).to eq(200)
    end
  end

  describe "throttles" do
    it "allows requests within the per-IP limit and blocks the next request" do
      travel_to Time.current do
        2.times { expect(request_status("/", "9.9.9.9")).to eq(200) }
        expect(request_status("/", "9.9.9.9")).to eq(429)
      end
    end

    it "throttles requests sharing an IP range" do
      travel_to Time.current do
        expect(request_status("/", "8.8.1.1")).to eq(200)
        expect(request_status("/", "8.8.2.2")).to eq(200)
        expect(request_status("/", "8.8.3.3")).to eq(429)
      end
    end

    it "does not throttle Active Storage requests" do
      travel_to Time.current do
        3.times do
          expect(request_status("/rails/active_storage/blobs/test", "7.7.7.7")).to eq(200)
        end
      end
    end
  end
end
