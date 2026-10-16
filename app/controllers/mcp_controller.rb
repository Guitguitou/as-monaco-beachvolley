# frozen_string_literal: true

# Endpoint MCP (Streamable HTTP, sans état) du connecteur Claude du Staff.
# Cf. docs/adr/0001.
class McpController < ActionController::API
  REQUIRED_SCOPE = "read"

  def create
    token = Doorkeeper::OAuth::Token.authenticate(request, *Doorkeeper.config.access_token_methods)
    return challenge(MCP::Server::OAuth::Challenge.missing_token_response(resource_metadata:)) if token.nil?
    return challenge(MCP::Server::OAuth::Challenge.invalid_token_response(resource_metadata:)) unless token.accessible?
    return insufficient_scope unless token.includes_scope?(REQUIRED_SCOPE)

    user = User.find_by(id: token.resource_owner_id)
    return head(:forbidden) unless Mcp::Access.granted_to?(user)

    reply = Mcp::ServerFactory.build(context: Mcp::Context.new(user:)).handle_json(request.raw_post)
    reply ? render(json: reply) : head(:accepted)
  end

  # Serveur sans état : pas de flux SSE ni de session à fermer.
  def method_not_allowed
    head :method_not_allowed
  end

  private

  def insufficient_scope
    challenge(MCP::Server::OAuth::Challenge.insufficient_scope_response(scope: REQUIRED_SCOPE, resource_metadata:))
  end

  def challenge((status, headers, body))
    response.headers.merge!(headers)
    render status:, body: body.join, content_type: headers["content-type"]
  end

  def resource_metadata
    "#{request.base_url}/.well-known/oauth-protected-resource/mcp"
  end
end
