# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditPurchases::Start do
  let(:user) { create(:user) }
  let(:payment_request) { instance_double("PaymentRequest") }

  before do
    allow(Sherlock::CreatePayment).to receive(:new).and_return(instance_double(Sherlock::CreatePayment, call: payment_request))
  end

  it "opens a pending purchase at the pack price and prepares its payment" do
    pack = create(:pack, pack_type: "credits", credits: 1000, amount_cents: 1500)

    purchase, request = described_class.new(user: user, pack: pack).call

    expect(purchase).to have_attributes(user: user, pack: pack, amount_cents: 1500, currency: "EUR", credits: 1000, status: "pending")
    expect(request).to eq(payment_request)
    expect(Sherlock::CreatePayment).to have_received(:new).with(purchase)
  end

  it "credits nothing for a pack without credits" do
    pack = create(:pack, pack_type: "equipements", credits: nil, amount_cents: 3000)

    purchase, = described_class.new(user: user, pack: pack).call

    expect(purchase.credits).to eq(0)
  end
end
