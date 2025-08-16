require 'rails_helper'

RSpec.describe Level, type: :model do
  it 'has gender enum values' do
    expect(Level.genders.keys).to contain_exactly('male', 'female', 'mixed')
  end

  describe '#display_name' do
    it 'appends M for male' do
      level = Level.new(name: 'A', gender: 'male')
      expect(level.display_name).to eq('A M')
    end

    it 'appends F for female' do
      level = Level.new(name: 'B', gender: 'female')
      expect(level.display_name).to eq('B F')
    end

    it 'appends X for mixed' do
      level = Level.new(name: 'C', gender: 'mixed')
      expect(level.display_name).to eq('C X')
    end
  end
end
