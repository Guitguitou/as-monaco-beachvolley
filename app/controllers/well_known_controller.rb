# frozen_string_literal: true

# Métadonnées OAuth lues par Claude pour découvrir comment se connecter au
# serveur MCP (RFC 9728 et RFC 8414).
class WellKnownController < ActionController::API
  # Claude demande tous les scopes annoncés : n'annoncer que ceux que le client
  # OAuth peut obtenir, sinon l'autorisation échoue en invalid_scope.
  # `write` sera ajouté ici et au client avec la phase 2 (écriture).
  SCOPES = %w[read].freeze

  def protected_resource
    render json: {
      resource: "#{issuer}/mcp",
      authorization_servers: [ issuer ],
      scopes_supported: SCOPES,
      bearer_methods_supported: [ "header" ],
      resource_name: "AS Monaco Beach Volley"
    }
  end

  def authorization_server
    render json: {
      issuer:,
      authorization_endpoint: "#{issuer}/oauth/authorize",
      token_endpoint: "#{issuer}/oauth/token",
      revocation_endpoint: "#{issuer}/oauth/revoke",
      scopes_supported: SCOPES,
      response_types_supported: [ "code" ],
      grant_types_supported: %w[authorization_code refresh_token],
      code_challenge_methods_supported: [ "S256" ],
      token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post]
    }
  end

  private

  def issuer
    request.base_url
  end
end
