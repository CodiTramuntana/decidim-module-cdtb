# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cdtb::IpParser do
  describe "::extract_ip" do
    let(:remote_addr) { "172.20.0.1" }
    let(:request_env) do
      h= {
        "REMOTE_ADDR" => remote_addr
      }
      h["HTTP_X_FORWARDED_FOR"]= forwarded_for if defined? forwarded_for
      h
    end
    let(:request) { ActionDispatch::Request.new(request_env) }

    it "parses IPs from standard request .ip method" do
      expect(Cdtb::IpParser.extract_ip(request)).to eq("172.20.0.1")
    end

    context "with HTTP_X_FORWARDED_FOR" do
      let(:forwarded_for) { "1.2.3.4" }

      it "parses IPs from forwarded for header" do
        expect(Cdtb::IpParser.extract_ip(request)).to eq("1.2.3.4")
      end
    end

    context "with port in the remote IP" do
      let(:remote_addr) { "1.1.1.1:1234" }

      it "parses IPs with port in them" do
        expect(Cdtb::IpParser.extract_ip(request)).to eq("1.1.1.1")
      end
    end

    context "with an IP o type inet6" do
      let(:remote_addr) { "94:e2:3c:a9:c2:48" }

      it "returs IPs of type inet6 as they are" do
        expect(Cdtb::IpParser.extract_ip(request)).to eq("94:e2:3c:a9:c2:48")
      end
    end

    context "decorating Rack::Request" do
      describe "#ip" do
        let(:remote_addr) { "10.20.30.1:1020301" }

        it "now ignores the port if set" do
          Cdtb::IpParser.decorate_rack_request
          expect(Rack::Request.new(request_env).ip).to eq("10.20.30.1")
        end
      end
    end
  end
end
