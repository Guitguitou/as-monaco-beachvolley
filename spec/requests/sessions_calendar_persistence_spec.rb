require 'rails_helper'
require 'erb'

RSpec.describe "Sessions calendar date persistence", type: :request do
  let(:user) { create(:user) }

  before do
    login_as user, scope: :user
  end

  it 'renders data-initial-date from params[:date] on the calendar container' do
    target_date = '2025-10-06'

    get sessions_path(date: target_date)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-initial-date="#{target_date}"))
  end

  it 'preserves the date param in terrain tabs links and after navigation' do
    target_date = '2025-10-06'

    get sessions_path(date: target_date)
    expect(response).to have_http_status(:ok)

    # Ensure the Terrain 2 tab link includes the date param
    expected_href = sessions_path(terrain: 'Terrain 2', date: target_date)
    expected_href_escaped = ERB::Util.html_escape(expected_href)
    expect(response.body).to include(%(href="#{expected_href_escaped}"))

    # Follow the Terrain 2 link and ensure the date is still passed through
    get expected_href
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-initial-date="#{target_date}"))
  end
end
