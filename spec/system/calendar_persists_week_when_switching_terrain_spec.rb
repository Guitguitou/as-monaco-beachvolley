# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Calendar week persistence across terrain switch', type: :system, js: true do
  let(:user) { create(:user) }

  before do
    login_as user, scope: :user
  end

  it 'keeps the selected week when navigating and switching terrain' do
    # Start on a known Monday so that week shifts are predictable
    initial_date = '2025-10-06'
    expected_next_date = (Date.parse(initial_date) + 7).strftime('%Y-%m-%d')
    visit sessions_path(date: initial_date)

    # Wait for FullCalendar to render (title present, buttons present)
    expect(page).to have_css('#calendar .fc-toolbar-title')
    expect(page).to have_selector('#calendar .fc-next-button')

    # Move to next week via FullCalendar button
    find('#calendar .fc-next-button').click

    # URL should be updated with new date param (Monday of next week)
    expect(page).to have_current_path(/\?(.+&)?date=#{expected_next_date}(&.+)?$/, url: true)

    # Click terrain 2 tab; the URL should keep the same date
    click_link 'Terrain 2'

    # Date param should be preserved after switching terrain
    expect(page).to have_current_path(/\?(.+&)?date=#{expected_next_date}(&.+)?$/, url: true)
    expect(page.current_url).to match(/terrain=Terrain\+2/)

    # And the calendar should still be present
    expect(page).to have_css('#calendar', visible: :all)
  end
end
