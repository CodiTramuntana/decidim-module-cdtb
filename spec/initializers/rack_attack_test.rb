# frozen_string_literal: true

require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled= true
    Rack::Attack.cache.store.clear
  end

  teardown do
    Rack::Attack.enabled= false
  end

  context "blocklist" do
    should "block requests to *.php files" do
      get "/wp-login.php"
      assert_response :forbidden
    end

    should "block requests from a blocklisted IP" do
      RACK_ATTACK_BLOQUED_IPS.push("64.226.110.113")
      begin
        get "/", env: { "REMOTE_ADDR" => "64.226.110.113" }
        assert_response :forbidden
      ensure
        RACK_ATTACK_BLOQUED_IPS.clear
      end
    end

    should "allow requests from a non blocklisted IP" do
      get "/", env: { "REMOTE_ADDR" => "1.2.3.4" }
      assert_response :redirect
    end

    should "block requests from an IP reported in abuse_reported_ips.csv" do
      get "/", env: { "REMOTE_ADDR" => "203.0.113.55" }
      assert_response :forbidden
    end
  end

  context "throttle requests by ip" do
    should "allow requests within the limit and block once exceeded" do
      # Freeze time so all requests fall in the same throttle period bucket.
      travel_to Time.current do
        limit= Rack::Attack.throttles["requests by ip"].limit
        env= { "REMOTE_ADDR" => "9.9.9.9" }

        # "/" redirects anonymous users to sign_in, but that's still an allowed (non-throttled) response.
        limit.times do
          get("/", env:)
          assert_response :redirect
        end

        get("/", env:)
        assert_response 429
      end
    end
  end

  context "throttle requests to sign_in" do
    should "allow requests within the limit and block once exceeded" do
      # Freeze time so all requests fall in the same throttle period bucket.
      travel_to Time.current do
        env= { "REMOTE_ADDR" => "8.8.8.8" }

        5.times do
          get("/users/sign_in", env:)
          assert_response :success
        end

        get("/users/sign_in", env:)
        assert_response 429
      end
    end
  end
end
