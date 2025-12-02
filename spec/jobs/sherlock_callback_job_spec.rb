# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SherlockCallbackJob, type: :job do
  let(:callback_params) do
    {
      reference: "REF-123",
      status: "paid"
    }
  end
  let(:handle_callback_service) { instance_double(Sherlock::HandleCallback) }

  describe '#perform' do
    it 'calls HandleCallback service with params' do
      expect(Sherlock::HandleCallback).to receive(:new).with(callback_params).and_return(handle_callback_service)
      expect(handle_callback_service).to receive(:call)
      
      described_class.perform_now(callback_params)
    end

    it 'passes params correctly to HandleCallback' do
      expect(Sherlock::HandleCallback).to receive(:new).with(callback_params).and_return(handle_callback_service)
      allow(handle_callback_service).to receive(:call)
      
      described_class.perform_now(callback_params)
    end
  end
end

