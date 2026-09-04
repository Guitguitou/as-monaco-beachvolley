require "rails_helper"

RSpec.describe AddToCalendarComponent, type: :component do
  it "renders a plain .ics link when no Google URL is given" do
    render_inline(described_class.new(url: "/sessions/1/calendar.ics"))

    link = page.find("a")
    expect(link[:href]).to eq("/sessions/1/calendar.ics")
    expect(link[:"data-controller"]).to be_nil
  end

  it "wires the Stimulus controller when a Google URL is given" do
    render_inline(described_class.new(
      url: "/sessions/1/calendar.ics",
      google_url: "https://calendar.google.com/calendar/render?action=TEMPLATE"
    ))

    link = page.find("a")
    expect(link[:"data-controller"]).to eq("add-to-calendar")
    expect(link[:"data-add-to-calendar-google-url-value"])
      .to eq("https://calendar.google.com/calendar/render?action=TEMPLATE")
  end
end
