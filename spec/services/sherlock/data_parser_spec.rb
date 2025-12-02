# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::DataParser do
  describe '.parse' do
    it 'parses a data string into a hash' do
      data_string = "key1=value1|key2=value2|key3=value3"
      result = described_class.parse(data_string)
      
      expect(result).to eq({
        "key1" => "value1",
        "key2" => "value2",
        "key3" => "value3"
      })
    end

    it 'handles empty string' do
      result = described_class.parse("")
      expect(result).to eq({})
    end

    it 'handles nil' do
      result = described_class.parse(nil)
      expect(result).to eq({})
    end

    it 'handles blank string' do
      result = described_class.parse("   ")
      expect(result).to eq({})
    end

    it 'handles single key-value pair' do
      result = described_class.parse("key=value")
      expect(result).to eq({ "key" => "value" })
    end

    it 'handles values with equals sign' do
      result = described_class.parse("key=value=with=equals")
      expect(result).to eq({ "key" => "value=with=equals" })
    end

    it 'handles empty values' do
      result = described_class.parse("key1=|key2=value2")
      expect(result).to eq({ "key1" => "", "key2" => "value2" })
    end

    it 'handles keys without values' do
      result = described_class.parse("key1=|key2")
      expect(result["key1"]).to eq("")
      expect(result["key2"]).to be_nil
    end
  end
end

