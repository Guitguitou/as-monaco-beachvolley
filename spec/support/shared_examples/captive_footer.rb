# frozen_string_literal: true

# Vérifie que la signature partenaire Captive est présente dans le mail :
# logo inline, lien tracké, CTA — dans les versions HTML et texte. Ce
# comportement vient du layout mailer.html.erb / mailer.text.erb et du
# before_action d'ApplicationMailer.
RSpec.shared_examples "includes the Captive footer" do
  let(:captive_url) do
    "https://www.captive.fr/?utm_source=as_monaco_volley&utm_medium=email" \
      "&utm_campaign=partner_visibility&utm_content=notification_footer"
  end

  it "embeds the Captive logo and a tracked link in HTML and text parts" do
    html_body = mail.html_part&.body&.to_s || mail.body.to_s
    text_body = mail.text_part&.body&.to_s

    expect(html_body).to include(captive_url)

    # Le logo est référencé via un attachement inline (CID).
    logo = mail.attachments.find { |a| a.filename == ApplicationMailer::CAPTIVE_LOGO_CID }
    expect(logo).to be_present
    expect(logo.inline?).to be(true)
    expect(html_body).to include(logo.cid)

    if text_body
      expect(text_body).to include(captive_url)
    end
  end
end
