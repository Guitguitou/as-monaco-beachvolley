# frozen_string_literal: true

# Serveur d'autorisation OAuth 2.1 du connecteur MCP (cf. docs/adr/0001).
# Seul le Staff peut autoriser son Claude ; le serveur MCP revérifie le rôle à
# chaque requête, un jeton encore valide ne suffit donc pas.
Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    if current_user.nil?
      store_location_for(:user, request.fullpath)
      redirect_to new_user_session_url
    elsif !Mcp::Access.granted_to?(current_user)
      head :forbidden
    else
      current_user
    end
  end

  # Applications créées en console ou via `bin/rails mcp:create_client`.
  admin_authenticator { head :forbidden }

  grant_flows %w[authorization_code]
  # Obligatoire pour les clients publics ; le client Claude est confidentiel
  # (secret) et envoie de toute façon un code_challenge.
  force_pkce
  pkce_code_challenge_methods %w[S256]

  access_token_expires_in 1.hour
  use_refresh_token
  # La rotation du refresh token à chaque renouvellement fait du created_at
  # du jeton courant la date de dernière utilisation (cf. Mcp::ExpireIdleTokensJob).

  default_scopes :read
  optional_scopes :write
  enforce_configured_scopes

  hash_token_secrets
  hash_application_secrets

  force_ssl_in_redirect_uri !Rails.env.local?
end
