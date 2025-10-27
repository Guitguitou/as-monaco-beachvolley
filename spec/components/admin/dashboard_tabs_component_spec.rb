# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardTabsComponent, type: :component do
  let(:component) { described_class.new(active_tab: 'overview') }

  it 'renders the tabs component' do
    render_inline(component)

    expect(page).to have_css('[data-controller="tabs"]')
    expect(page).to have_button('Aperçu')
    expect(page).to have_button('Sessions')
    expect(page).to have_button('Finances')
    expect(page).to have_button('Coachs')
    expect(page).to have_button('Alertes')
  end

  it 'marks the active tab correctly' do
    render_inline(component)

    expect(page).to have_css('button.bg-asmbv-red.text-white', text: 'Aperçu')
    expect(page).to have_css('button.text-gray-600', text: 'Sessions')
  end

  context 'with different active tab' do
    let(:component) { described_class.new(active_tab: 'sessions') }

    it 'marks the correct tab as active' do
      render_inline(component)

      expect(page).to have_css('button.bg-asmbv-red.text-white', text: 'Sessions')
      expect(page).to have_css('button.text-gray-600', text: 'Aperçu')
    end
  end

  it 'includes turbo-frame for content' do
    render_inline(component)

    expect(page).to have_css('turbo-frame#dashboard-content')
  end
end
