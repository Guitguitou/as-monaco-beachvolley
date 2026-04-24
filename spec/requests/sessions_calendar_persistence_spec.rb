require "rails_helper"
require "erb"
require "cgi"
require "json"

RSpec.describe "Sessions calendar date persistence", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }

  before do
    login_as user, scope: :user
  end

  it "redirects to calendar with session week date and terrain after PATCH update" do
    coach = create(:user, :coach, activated_at: Time.current)
    session_date = Time.zone.parse("2030-01-15 10:00:00")
    session_record = create(:session, :terrain_2, user: coach, start_at: session_date, end_at: session_date + 1.hour)
    login_as coach, scope: :user

    patch "#{session_path(session_record)}?terrain=Terrain+2&view=calendar", params: {
      session: {
        title: session_record.title,
        description: session_record.description,
        start_at: session_record.start_at,
        end_at: session_record.end_at,
        session_type: session_record.session_type,
        terrain: session_record.terrain,
        user_id: session_record.user_id,
        max_players: session_record.max_players
      }
    }

    expect(response).to redirect_to(sessions_path(date: "2030-01-15", terrain: "Terrain 2", view: "calendar"))
  end

  it "keeps for_me in redirect after PATCH update" do
    coach = create(:user, :coach, activated_at: Time.current)
    session_date = Time.zone.parse("2030-01-16 10:00:00")
    session_record = create(:session, :terrain_2, user: coach, start_at: session_date, end_at: session_date + 1.hour)
    login_as coach, scope: :user

    patch "#{session_path(session_record)}?terrain=Terrain+2&for_me=1&view=calendar", params: {
      session: {
        title: session_record.title,
        description: session_record.description,
        start_at: session_record.start_at,
        end_at: session_record.end_at,
        session_type: session_record.session_type,
        terrain: session_record.terrain,
        user_id: session_record.user_id,
        max_players: session_record.max_players
      }
    }

    expect(response).to redirect_to(sessions_path(date: "2030-01-16", terrain: "Terrain 2", for_me: "1", view: "calendar"))
  end

  it "redirects to calendar with session date (no terrain) when terrain was not in request" do
    coach = create(:user, :coach, activated_at: Time.current)
    session_date = Time.zone.parse("2030-02-20 14:00:00")
    session_record = create(:session, :terrain_3, user: coach, start_at: session_date, end_at: session_date + 1.hour)
    login_as coach, scope: :user

    patch session_path(session_record, view: "calendar"), params: {
      session: {
        title: session_record.title,
        description: session_record.description,
        start_at: session_record.start_at,
        end_at: session_record.end_at,
        session_type: session_record.session_type,
        terrain: session_record.terrain,
        user_id: session_record.user_id,
        max_players: session_record.max_players
      }
    }

    expect(response).to redirect_to(sessions_path(date: "2030-02-20", view: "calendar"))
  end

  it "renders data-initial-date from params[:date] on the calendar container" do
    target_date = '2025-10-06'

    get sessions_path(date: target_date, view: "calendar")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-initial-date="#{target_date}"))
  end

  it 'preserves the date param in terrain tabs links and after navigation' do
    target_date = '2025-10-06'

    get sessions_path(date: target_date, view: "calendar")
    expect(response).to have_http_status(:ok)

    # Ensure the Terrain 2 tab link includes the date param
    expected_href = sessions_path(terrain: "Terrain 2", date: target_date, view: "calendar")
    expected_href_escaped = ERB::Util.html_escape(expected_href)
    expect(response.body).to include(%(href="#{expected_href_escaped}"))

    # Follow the Terrain 2 link and ensure the date is still passed through
    get expected_href
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-initial-date="#{target_date}"))
  end

  it "filters sessions for me and keeps for_me in terrain links" do
    coach = create(:user, :coach, activated_at: Time.current)
    matching_level = create(:level, name: "G1")
    other_level = create(:level, name: "G2")
    create(:user_level, user: user, level: matching_level)

    public_training = create(:session, user: coach, session_type: "entrainement")
    group_training_for_user = create(:session, user: coach, session_type: "entrainement")
    group_training_for_other = create(:session, user: coach, session_type: "entrainement")
    non_training = create(:session, :jeu_libre, user: coach)

    create(:session_level, session: group_training_for_user, level: matching_level)
    create(:session_level, session: group_training_for_other, level: other_level)

    get sessions_path(view: "calendar", for_me: "1")

    expect(response).to have_http_status(:ok)

    calendar_data = CGI.unescapeHTML(response.body[/data-sessions="([^"]+)"/, 1])
    parsed_events = JSON.parse(calendar_data)
    event_ids = parsed_events.map { |event| event["id"] }

    expect(event_ids).to include(public_training.id, group_training_for_user.id, non_training.id)
    expect(event_ids).not_to include(group_training_for_other.id)

    expected_href = sessions_path(terrain: "Terrain 2", for_me: "1", view: "calendar")
    expected_href_escaped = ERB::Util.html_escape(expected_href)
    expect(response.body).to include(%(href="#{expected_href_escaped}"))
  end
end
