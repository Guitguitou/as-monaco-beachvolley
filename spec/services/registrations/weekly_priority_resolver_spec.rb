require 'rails_helper'

RSpec.describe Registrations::WeeklyPriorityResolver do
  let(:monday) { Time.zone.parse('2035-01-01 10:00:00') } # un lundi, hors des données résiduelles de la base de test
  let(:level) { create(:level) }
  let(:user) { create(:user, level: level) }

  around { |example| travel_to(monday) { example.run } }

  before { create(:credit_transaction, user: user, amount: 100_000) }

  # Un entraînement sur la semaine prochaine, à l'heure et sur le terrain voulus.
  def training(day_offset:, hour:, terrain: 'Terrain 1', week_offset: 7, **attrs)
    start_at = (monday + week_offset.days + day_offset.days).change(hour: hour)
    create(:session,
           session_type: 'entrainement',
           levels: [ level ],
           terrain: terrain,
           start_at: start_at,
           end_at: start_at + 1.hour,
           registration_opens_at: monday - 1.day,
           **attrs)
  end

  def rank(session, registration)
    described_class.new(session: session).rank_for(registration)
  end

  describe 'semaine en cours' do
    it 'est neutre pour tout le monde, même avec plusieurs entraînements' do
      s1 = training(day_offset: 1, hour: 10, week_offset: 0)
      s2 = training(day_offset: 2, hour: 10, terrain: 'Terrain 2', week_offset: 0)
      create(:registration, user: user, session: s1, status: :confirmed)
      reg = create(:registration, user: user, session: s2, status: :confirmed)

      expect(rank(s2, reg)).to eq(Registrations::WeeklyPriorityRule::PRIORITY)
    end
  end

  describe 'semaine à venir' do
    it 'est prioritaire sans autre entraînement' do
      session = training(day_offset: 1, hour: 10)
      reg = create(:registration, user: user, session: session, status: :confirmed)

      expect(rank(session, reg)).to eq(0)
    end

    it 'déclasse la deuxième inscription et garde la première prioritaire' do
      s1 = training(day_offset: 1, hour: 10)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')

      first = create(:registration, user: user, session: s1, status: :confirmed)
      travel 1.minute
      second = create(:registration, user: user, session: s2, status: :confirmed)

      # Le point clé : jamais [1, 1], sinon le joueur serait démoté des deux.
      expect([ rank(s1, first), rank(s2, second) ]).to eq([ 0, 1 ])
    end

    it 'départage par id quand les created_at sont identiques' do
      s1 = training(day_offset: 1, hour: 10)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')

      first = create(:registration, user: user, session: s1, status: :confirmed)
      second = create(:registration, user: user, session: s2, status: :confirmed)

      expect(first.created_at).to eq(second.created_at)
      expect([ rank(s1, first), rank(s2, second) ]).to eq([ 0, 1 ])
    end

    it 'ignore un pair en liste d\'attente' do
      s1 = training(day_offset: 1, hour: 10)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')
      create(:registration, :waitlisted, user: user, session: s1)
      travel 1.minute
      reg = create(:registration, user: user, session: s2, status: :confirmed)

      expect(rank(s2, reg)).to eq(0)
    end

    it 'ignore un jeu libre' do
      libre = create(:session, :jeu_libre, terrain: 'Terrain 3',
                                start_at: (monday + 8.days).change(hour: 10),
                                end_at: (monday + 8.days).change(hour: 11))
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')
      create(:registration, user: user, session: libre, status: :confirmed)
      travel 1.minute
      reg = create(:registration, user: user, session: s2, status: :confirmed)

      expect(rank(s2, reg)).to eq(0)
    end

    it 'ignore un entraînement d\'une autre semaine' do
      s1 = training(day_offset: 1, hour: 10, week_offset: 14)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')
      create(:registration, user: user, session: s1, status: :confirmed)
      travel 1.minute
      reg = create(:registration, user: user, session: s2, status: :confirmed)

      expect(rank(s2, reg)).to eq(0)
    end

    it 'ne considère jamais la session comme son propre pair' do
      session = training(day_offset: 1, hour: 10)
      reg = create(:registration, user: user, session: session, status: :confirmed)

      expect(rank(session, reg)).to eq(0)
    end

    it 'rattache un entraînement du dimanche soir à la semaine du dimanche' do
      sunday = training(day_offset: 6, hour: 22, terrain: 'Terrain 2')
      next_monday = training(day_offset: 7, hour: 10, terrain: 'Terrain 3')
      create(:registration, user: user, session: sunday, status: :confirmed)
      travel 1.minute
      reg = create(:registration, user: user, session: next_monday, status: :confirmed)

      expect(rank(next_monday, reg)).to eq(0)
    end
  end

  describe '#rank_for_new' do
    it 'déclasse une inscription hypothétique dès qu\'un pair existe' do
      s1 = training(day_offset: 1, hour: 10)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')
      create(:registration, user: user, session: s1, status: :confirmed)

      resolver = described_class.new(session: s2)
      expect(resolver.rank_for_new(user.id)).to eq(1)
    end

    it 'reste prioritaire sans pair' do
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2')
      expect(described_class.new(session: s2).rank_for_new(user.id)).to eq(0)
    end
  end

  describe 'coût en requêtes' do
    it 'ne fait qu\'une requête pour tout un lot d\'inscriptions' do
      s1 = training(day_offset: 1, hour: 10)
      s2 = training(day_offset: 3, hour: 10, terrain: 'Terrain 2', max_players: 20)
      create(:registration, user: user, session: s1, status: :confirmed)

      registrations = Array.new(5) do
        other = create(:user, level: level)
        create(:credit_transaction, user: other, amount: 100_000)
        create(:registration, user: other, session: s2, status: :confirmed)
      end
      registrations << create(:registration, user: user, session: s2, status: :confirmed)

      resolver = described_class.new(session: s2)
      count = 0
      counter = ->(*) { count += 1 }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        resolver.prime(registrations)
        registrations.each { |registration| resolver.rank_for(registration) }
      end

      expect(count).to eq(1)
    end
  end
end
