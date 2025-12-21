# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionLevel, type: :model do
  it 'belongs to session and level' do
    s = create(:session, terrain: 'Terrain 1')
    l = create(:level)
    sl = described_class.create!(session: s, level: l)
    expect(sl.session).to eq(s)
    expect(sl.level).to eq(l)
  end
end
