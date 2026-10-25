# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicPages::FetchMeta do
  let(:url) { "https://script.google.com/macros/s/abc/exec" }

  def stub_response(body)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    allow(response).to receive(:body).and_return(body)
    allow(Net::HTTP).to receive(:start).and_return(response)
  end

  it "reprend le titre et les balises Open Graph" do
    stub_response(<<~HTML)
      <html><head>
        <title>Tournoi de Noël en direct</title>
        <meta property="og:description" content=" Samedi festif ">
        <meta property="og:image" content="https://example.com/noel.png">
      </head></html>
    HTML

    expect(described_class.new.call(url)).to eq(
      meta_title: "Tournoi de Noël en direct",
      meta_description: "Samedi festif",
      meta_image: "https://example.com/noel.png"
    )
  end

  it "ne reprend rien si le script est injoignable" do
    allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)

    expect(described_class.new.call(url)).to eq({})
  end
end
