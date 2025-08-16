require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }
  let(:level) { create(:level) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      session = build(:session, user: user, levels: [level])
      expect(session).to be_valid
    end

    it 'requires title' do
      session = build(:session, title: nil, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:title]).to include("Le titre est obligatoire")
    end

    it 'requires start_at' do
      session = build(:session, start_at: nil, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:start_at]).to include("La date de début est obligatoire")
    end

    it 'requires end_at' do
      session = build(:session, end_at: nil, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:end_at]).to include("La date de fin est obligatoire")
    end

    it 'requires session_type' do
      session = build(:session, session_type: nil, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:session_type]).to include("Le type de session est obligatoire")
    end

    it 'requires terrain' do
      session = build(:session, terrain: nil, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:terrain]).to include("Le terrain est obligatoire")
    end

    it 'requires user_id' do
      session = build(:session, user: nil, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:user_id]).to include("L'organisateur est obligatoire")
    end

    it 'validates end_at is after start_at' do
      session = build(:session, start_at: 1.hour.from_now, end_at: 30.minutes.from_now, user: user, levels: [level])
      expect(session).not_to be_valid
      expect(session.errors[:end_at]).to include("doit être après la date de début")
    end
  end

  describe 'enums' do
    it 'defines session_type enum' do
      expect(Session.session_types).to include(
        'entrainement' => 'entrainement',
        'jeu_libre' => 'jeu_libre',
        'tournoi' => 'tournoi',
        'coaching_prive' => 'coaching_prive'
      )
    end

    it 'defines terrain enum' do
      expect(Session.terrains).to include(
        'Terrain 1' => 1,
        'Terrain 2' => 2,
        'Terrain 3' => 3
      )
    end
  end

  describe 'terrain overlap validation' do
    let!(:existing_session) do
      create(:session, 
        user: user, 
        levels: [level],
        terrain: 'Terrain 1',
        start_at: 2.hours.from_now,
        end_at: 4.hours.from_now
      )
    end

    it 'prevents overlapping sessions on the same terrain' do
      overlapping_session = build(:session,
        user: user,
        levels: [level],
        terrain: 'Terrain 1',
        start_at: 3.hours.from_now,
        end_at: 5.hours.from_now
      )
      
      expect(overlapping_session).not_to be_valid
      expect(overlapping_session.errors[:base]).to include("Une session existe déjà sur ce terrain pendant ces horaires")
    end

    it 'allows sessions on different terrains' do
      different_terrain_session = build(:session,
        user: user,
        levels: [level],
        terrain: 'Terrain 2',
        start_at: 3.hours.from_now,
        end_at: 5.hours.from_now
      )
      
      expect(different_terrain_session).to be_valid
    end

    it 'allows non-overlapping sessions on the same terrain' do
      non_overlapping_session = build(:session,
        user: user,
        levels: [level],
        terrain: 'Terrain 1',
        start_at: 5.hours.from_now,
        end_at: 7.hours.from_now
      )
      
      expect(non_overlapping_session).to be_valid
    end

    it 'allows updating a session without creating overlap with itself' do
      existing_session.title = "Updated Title"
      expect(existing_session).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      session = create(:session, user: user, levels: [level])
      expect(session.user).to eq(user)
    end

    it 'has many session_levels' do
      session = create(:session, user: user, levels: [level])
      expect(session.session_levels).to be_present
    end

    it 'has many levels through session_levels' do
      session = create(:session, user: user, levels: [level])
      expect(session.levels).to include(level)
    end
  end

  describe '#display_name' do
    it 'returns title with levels for entrainement' do
      session = create(:session, 
        session_type: :entrainement, 
        title: "Entraînement", 
        user: user, 
        levels: [level]
      )
      expect(session.display_name).to eq("Entraînement - #{level.display_name}")
    end

    it 'returns title for jeu_libre' do
      session = create(:session, 
        session_type: :jeu_libre, 
        title: "Jeu libre", 
        user: user, 
        levels: [level]
      )
      expect(session.display_name).to eq("Jeu libre")
    end

    it 'returns title for tournoi' do
      session = create(:session, 
        session_type: :tournoi, 
        title: "Tournoi", 
        user: user, 
        levels: [level]
      )
      expect(session.display_name).to eq("Tournoi")
    end

    it 'returns title for coaching_prive' do
      # Ensure coach has enough credits to pass validation
      create(:credit_transaction, user: user, amount: 2_000)
      session = create(:session, 
        session_type: :coaching_prive, 
        title: "Coaching", 
        user: user, 
        levels: [level]
      )
      expect(session.display_name).to eq("Coaching")
    end
  end
end
