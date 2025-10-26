require 'rails_helper'

RSpec.describe Pack, type: :model do
  describe 'associations' do
    it 'has many credit purchases' do
      expect(Pack.reflect_on_association(:credit_purchases).macro).to eq(:has_many)
    end

    it 'belongs to stage' do
      expect(Pack.reflect_on_association(:stage).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      pack = build(:pack, name: nil)
      expect(pack).not_to be_valid
      expect(pack.errors[:name]).not_to be_empty
    end

    it 'validates presence of amount_cents' do
      pack = build(:pack, amount_cents: nil)
      expect(pack).not_to be_valid
      expect(pack.errors[:amount_cents]).not_to be_empty
    end

    it 'validates presence of pack_type' do
      pack = build(:pack, pack_type: nil)
      expect(pack).not_to be_valid
      expect(pack.errors[:pack_type]).not_to be_empty
    end

    it 'validates amount_cents is greater than 0' do
      pack = build(:pack, amount_cents: 0)
      expect(pack).not_to be_valid
      expect(pack.errors[:amount_cents]).not_to be_empty
    end

    context 'when pack_type is credits' do
      it 'validates presence of credits' do
        pack = build(:pack, :credits, credits: nil)
        expect(pack).not_to be_valid
        expect(pack.errors[:credits]).not_to be_empty
      end

      it 'validates credits is greater than 0' do
        pack = build(:pack, :credits, credits: 0)
        expect(pack).not_to be_valid
        expect(pack.errors[:credits]).not_to be_empty
      end
    end

    context 'when pack_type is stage' do
      it 'validates presence of stage_id' do
        pack = build(:pack, :stage, stage_id: nil)
        expect(pack).not_to be_valid
        expect(pack.errors[:stage_id]).not_to be_empty
      end
    end

    context 'when pack_type is licence' do
      it 'does not require credits' do
        pack = build(:pack, :licence, credits: nil)
        expect(pack).to be_valid
      end

      it 'does not require stage_id' do
        pack = build(:pack, :licence, stage_id: nil)
        expect(pack).to be_valid
      end
    end
  end

  describe 'enums' do
    it 'defines pack_type enum' do
      expect(Pack.pack_types).to eq({
        'credits' => 'credits',
        'licence' => 'licence',
        'stage' => 'stage'
      })
    end
  end

  describe 'scopes' do
    let!(:active_pack) { create(:pack, active: true) }
    let!(:inactive_pack) { create(:pack, active: false) }
    let!(:credits_pack) { create(:pack, :credits) }
    let!(:stage_pack) { create(:pack, :stage) }
    let!(:licence_pack) { create(:pack, :licence) }

    describe '.active' do
      it 'returns only active packs' do
        expect(Pack.active).to include(active_pack)
        expect(Pack.active).not_to include(inactive_pack)
      end
    end

    describe '.credits_packs' do
      it 'returns only credits packs' do
        expect(Pack.credits_packs).to include(credits_pack)
        expect(Pack.credits_packs).not_to include(stage_pack, licence_pack)
      end
    end

    describe '.stage_packs' do
      it 'returns only stage packs' do
        expect(Pack.stage_packs).to include(stage_pack)
        expect(Pack.stage_packs).not_to include(credits_pack, licence_pack)
      end
    end

    describe '.licence_packs' do
      it 'returns only licence packs' do
        expect(Pack.licence_packs).to include(licence_pack)
        expect(Pack.licence_packs).not_to include(credits_pack, stage_pack)
      end
    end
  end

  describe '#amount_eur' do
    it 'converts cents to euros' do
      pack = build(:pack, amount_cents: 1500)
      expect(pack.amount_eur).to eq(15.0)
    end
  end

  describe '#amount_eur=' do
    it 'converts euros to cents' do
      pack = build(:pack)
      pack.amount_eur = 25.50
      expect(pack.amount_cents).to eq(2550)
    end
  end

  describe '#display_name' do
    context 'for credits pack' do
      let(:pack) { build(:pack, :credits, name: 'Premium', credits: 2000, amount_cents: 2000) }
      
      it 'includes credits information' do
        expect(pack.display_name).to eq('Premium - 2000 crédits (20.0 €)')
      end
    end

    context 'for stage pack' do
      let(:stage) { build(:stage, title: 'Stage Été') }
      let(:pack) { build(:pack, :stage, name: 'Pack Stage', stage: stage, amount_cents: 5000) }
      
      it 'includes stage information' do
        expect(pack.display_name).to eq('Pack Stage - Stage Été (50.0 €)')
      end
    end

    context 'for licence pack' do
      let(:pack) { build(:pack, :licence, name: 'Licence Annuelle', amount_cents: 10000) }
      
      it 'includes licence information' do
        expect(pack.display_name).to eq('Licence Annuelle - Licence (100.0 €)')
      end
    end
  end

  describe '#credits_per_euro' do
    context 'for credits pack' do
      let(:pack) { build(:pack, :credits, credits: 2000, amount_cents: 2000) }
      
      it 'calculates credits per euro' do
        expect(pack.credits_per_euro).to eq(100.0)
      end
    end

    context 'for non-credits pack' do
      let(:pack) { build(:pack, :licence) }
      
      it 'returns 0' do
        expect(pack.credits_per_euro).to eq(0)
      end
    end
  end
end
