# frozen_string_literal: true

# Vérifie que la mention "Application développée et maintenue par l'agence Captive"
# est présente dans le mail, dans les versions HTML ET texte, avec le bon lien
# de tracking. Ce comportement vient du layout mailer.html.erb / mailer.text.erb.
RSpec.shared_examples "includes the Captive footer" do
  let(:captive_url) do
    "https://www.captive.fr/?utm_source=as_monaco_volley&utm_medium=email" \
      "&utm_campaign=partner_visibility&utm_content=notification_footer"
  end

  it "includes the Captive mention and tracked link in HTML and text parts" do
    html_body = mail.html_part&.body&.to_s || mail.body.to_s
    text_body = mail.text_part&.body&.to_s

    expect(html_body).to include("Captive")
    expect(html_body).to include("Application développée et maintenue")
    expect(html_body).to include(captive_url)

    if text_body
      expect(text_body).to include("Captive")
      expect(text_body).to include(captive_url)
    end
  end
end
