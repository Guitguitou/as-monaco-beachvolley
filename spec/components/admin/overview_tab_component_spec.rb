# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::OverviewTabComponent, type: :component do
  let(:kpis) do
    {
      trainings_count: 5,
      free_plays_count: 3,
      private_coachings_count: 2,
      late_cancellations_count: 1,
      revenue: 1500.0,
      coach_salaries: 800.0,
      net_profit: 700.0
    }
  end
  let(:upcoming_sessions) do
    {
      trainings: [],
      free_plays: [],
      private_coachings: []
    }
  end
  let(:alerts) do
    {
      late_cancellations: [],
      capacity_alerts: [],
      low_attendance: [],
      upcoming_sessions: []
    }
  end
  let(:component) { described_class.new(kpis: kpis, upcoming_sessions: upcoming_sessions, alerts: alerts) }

  it 'renders the overview tab component' do
    render_inline(component)

    expect(page).to have_css('.space-y-6')
  end

  it 'displays KPI cards' do
    render_inline(component)

    expect(page).to have_text('Entraînements (semaine)')
    expect(page).to have_text('5')
    expect(page).to have_text('Jeux libres (semaine)')
    expect(page).to have_text('3')
    expect(page).to have_text('Coachings privés (semaine)')
    expect(page).to have_text('2')
    expect(page).to have_text('Désinscriptions hors délai')
    expect(page).to have_text('1')
    expect(page).to have_text('CA semaine (€)')
    expect(page).to have_text('1500.00')
    expect(page).to have_text('Salaires coachs (€)')
    expect(page).to have_text('800.00')
    expect(page).to have_text('Différence (€)')
    expect(page).to have_text('700.00')
  end

  it 'displays upcoming sessions sections' do
    render_inline(component)

    expect(page).to have_text('Entraînements à venir')
    expect(page).to have_text('Jeux libres à venir')
    expect(page).to have_text('Coachings privés à venir')
  end

  context 'with upcoming sessions' do
    let!(:coach) do
      user = create(:user, coach: true)
      user.balance.update!(amount: 2000) # Enough for private coaching
      user
    end
    let!(:training_session) do
      create(:session, 
             session_type: 'entrainement', 
             start_at: 1.day.from_now,
             end_at: 1.day.from_now + 2.hours,
             user: coach,
             title: 'Entraînement Test')
    end
    let!(:free_play_session) do
      create(:session, 
             session_type: 'jeu_libre', 
             start_at: 2.days.from_now,
             end_at: 2.days.from_now + 2.hours,
             user: coach,
             title: 'Jeu Libre Test')
    end
    let!(:private_coaching_session) do
      create(:session, 
             session_type: 'coaching_prive', 
             start_at: 3.days.from_now,
             end_at: 3.days.from_now + 2.hours,
             user: coach,
             title: 'Coaching Privé Test')
    end

    let(:upcoming_sessions) do
      {
        trainings: [training_session],
        free_plays: [free_play_session],
        private_coachings: [private_coaching_session]
      }
    end

    it 'displays upcoming sessions' do
      render_inline(component)

      expect(page).to have_text('Entraînement Test')
      expect(page).to have_text('Jeu Libre Test')
      expect(page).to have_text('Coaching Privé Test')
    end
  end

  context 'with no upcoming sessions' do
    it 'displays no sessions messages' do
      render_inline(component)

      expect(page).to have_text('Aucun entraînement prévu')
      expect(page).to have_text('Aucun jeu libre prévu')
      expect(page).to have_text('Aucun coaching privé prévu')
    end
  end

  it 'applies correct color classes for different KPI types' do
    render_inline(component)

    expect(page).to have_css('.bg-blue-50.text-blue-600') # trainings
    expect(page).to have_css('.bg-green-50.text-green-600') # free_plays
    expect(page).to have_css('.bg-purple-50.text-purple-600') # private_coachings
    expect(page).to have_css('.bg-red-50.text-red-600') # late_cancellations
  end
end
