# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardTabsComponent, type: :component do
  let(:component) { described_class.new(active_tab: 'overview') }

  it 'renders the tabs component' do
    render_inline(component)

    expect(page).to have_css('[data-controller="tabs"]')
    expect(page).to have_link('Vue d\'ensemble')
    expect(page).to have_link('Sessions')
    expect(page).to have_link('Finances')
    expect(page).to have_link('Coachs')
    expect(page).to have_link('Alertes')
  end

  it 'marks the active tab correctly' do
    render_inline(component)

    expect(page).to have_css('a.bg-asmbv-red.text-white', text: 'Vue d\'ensemble')
    expect(page).to have_css('a.text-gray-500', text: 'Sessions')
  end

  context 'with different active tab' do
    let(:component) { described_class.new(active_tab: 'sessions') }

    it 'marks the correct tab as active' do
      render_inline(component)

      expect(page).to have_css('a.bg-asmbv-red.text-white', text: 'Sessions')
      expect(page).to have_css('a.text-gray-500', text: 'Vue d\'ensemble')
    end
  end

  it 'renders tab content area' do
    render_inline(component) do
      "Test content"
    end

    expect(page).to have_text('Test content')
  end
end
