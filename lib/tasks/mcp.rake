# frozen_string_literal: true

namespace :mcp do
  desc "Crée le client OAuth du connecteur Claude et affiche ses identifiants (une seule fois)"
  task create_client: :environment do
    application = Doorkeeper::Application.create!(
      name: "Claude",
      redirect_uri: "https://claude.ai/api/mcp/auth_callback\nhttps://claude.com/api/mcp/auth_callback",
      scopes: "read",
      confidential: true
    )

    puts "Client ID     : #{application.uid}"
    puts "Client Secret : #{application.plaintext_secret}"
    puts "À saisir dans Claude > Connecteurs > Ajouter un connecteur personnalisé > Paramètres avancés."
    puts "Le secret est stocké haché : il ne sera plus jamais affiché."
  end
end
