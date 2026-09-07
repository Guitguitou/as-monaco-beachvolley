require 'rails_helper'

RSpec.describe Registrations::UserWeeklyPriorityMap do
  let(:monday) { Time.zone.parse('2035-01-01 10:00:00') } # un lundi, hors des données résiduelles de la base de test
  let(:level) { create(:level) }
  let(:user) { create(:user, level: level) }

  around { |example| travel_to(monday) { example.run } }

  before { create(:credit_transaction, user: user, amount: 100_000) }

  def training(day_offset:, terrain: 'Terrain 1', week_offset: 7, **attrs)
    start_at = (monday + week_offset.days + day_offset.days).change(hour: 10)
    create(:session,
           session_type: 'entrainement',
           levels: [ level ],
           terrain: terrain,
           start_at: start_at,
           end_at: start_at + 1.hour,
           registration_opens_at: monday - 1.day,
           **attrs)
  end

  it 'répartit les rangs semaine par semaine' do
    s1 = training(day_offset: 1)
    s2 = training(day_offset: 3, terrain: 'Terrain 2')
    s3 = training(day_offset: 1, terrain: 'Terrain 3', week_offset: 14)

    create(:registration, user: user, session: s1, status: :confirmed)

    ranks = described_class.call(user: user, sessions: [ s1, s2, s3 ])

    expect(ranks[s1.id]).to eq(0)
    expect(ranks[s2.id]).to eq(1) # 2e entraînement de la même semaine
    expect(ranks[s3.id]).to eq(0) # semaine suivante : reparti à zéro
  end

  it 'exclut les sessions qui ne sont pas des entraînements' do
    libre = create(:session, :jeu_libre, terrain: 'Terrain 3',
                              start_at: (monday + 8.days).change(hour: 10),
                              end_at: (monday + 8.days).change(hour: 11))

    expect(described_class.call(user: user, sessions: [ libre ])).to eq({})
  end

  it 'est neutre sur la semaine en cours' do
    s1 = training(day_offset: 1, week_offset: 0)
    s2 = training(day_offset: 3, terrain: 'Terrain 2', week_offset: 0)
    create(:registration, user: user, session: s1, status: :confirmed)

    expect(described_class.call(user: user, sessions: [ s2 ])[s2.id]).to eq(0)
  end

  it 'retourne un hash vide sans utilisateur' do
    expect(described_class.call(user: nil, sessions: [ training(day_offset: 1) ])).to eq({})
  end

  it 'ne fait qu\'une requête pour tout le lot' do
    sessions = [ training(day_offset: 1), training(day_offset: 3, terrain: 'Terrain 2'), training(day_offset: 5, terrain: 'Terrain 3') ]
    create(:registration, user: user, session: sessions.first, status: :confirmed)

    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      described_class.call(user: user, sessions: sessions)
    end

    expect(count).to eq(1)
  end
end
