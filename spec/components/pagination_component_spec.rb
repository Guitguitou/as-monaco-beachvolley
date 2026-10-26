# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaginationComponent, type: :component do
  let(:pagination) { instance_double(Pagination, multiple_pages?: true, current_page: 5, total_pages: 10, total_count: 200, prev_page: 4, next_page: 6) }

  it "affiche la première, la dernière et les pages autour de la courante" do
    render_inline(described_class.new(pagination: pagination, url_for: ->(page) { "/x?page=#{page}" }))

    expect(page.all("li a, li span[aria-current]").map(&:text).compact_blank).to eq(%w[1 3 4 5 6 7 10])
    expect(page).to have_css("span[aria-current='page']", text: "5")
    expect(page).to have_text("…")
  end

  it "ne s'affiche pas sur une seule page" do
    single = instance_double(Pagination, multiple_pages?: false)

    expect(render_inline(described_class.new(pagination: single, url_for: ->(_) { "/" })).to_html).to be_blank
  end
end
