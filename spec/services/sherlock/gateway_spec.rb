# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Gateway do
  describe '.build' do
    context 'when SHERLOCK_GATEWAY is set to real' do
      before do
        allow(ENV).to receive(:fetch).with('SHERLOCK_GATEWAY', 'fake').and_return('real')
      end

      it 'returns a RealGateway instance' do
        gateway = described_class.build
        expect(gateway).to be_a(Sherlock::RealGateway)
      end
    end

    context 'when SHERLOCK_GATEWAY is set to fake' do
      before do
        allow(ENV).to receive(:fetch).with('SHERLOCK_GATEWAY', 'fake').and_return('fake')
      end

      it 'returns a FakeGateway instance' do
        gateway = described_class.build
        expect(gateway).to be_a(Sherlock::FakeGateway)
      end
    end

    context 'when SHERLOCK_GATEWAY is not set' do
      before do
        allow(ENV).to receive(:fetch).with('SHERLOCK_GATEWAY', 'fake').and_return('fake')
      end

      it 'defaults to FakeGateway' do
        gateway = described_class.build
        expect(gateway).to be_a(Sherlock::FakeGateway)
      end
    end
  end

  describe '#create_payment' do
    it 'raises NotImplementedError' do
      gateway = described_class.new
      expect {
        gateway.create_payment(
          reference: "ref",
          amount_cents: 1000,
          currency: "EUR",
          return_urls: {},
          customer: {}
        )
      }.to raise_error(NotImplementedError)
    end
  end
end
