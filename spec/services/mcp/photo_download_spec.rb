# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mcp::PhotoDownload do
  def resolver(address) = class_double(Resolv, getaddress: address)

  it "refuse une URL qui n'est pas en https" do
    expect { described_class.new("http://example.com/photo.png").call }.to raise_error(ArgumentError, /https/)
  end

  it "refuse une adresse du réseau interne" do
    %w[127.0.0.1 10.0.0.4 192.168.1.1 169.254.169.254].each do |address|
      download = described_class.new("https://interne.example/photo.png", resolver: resolver(address))

      expect { download.call }.to raise_error(ArgumentError, /non autorisée/)
    end
  end

  it "signale une URL invalide" do
    expect { described_class.new("https://exa mple.com") }.to raise_error(ArgumentError, /invalide/)
  end
end
