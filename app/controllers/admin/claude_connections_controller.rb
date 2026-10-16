# frozen_string_literal: true

module Admin
  # Connexions Claude (connecteur MCP) du Staff, et leur révocation.
  class ClaudeConnectionsController < BaseController
    before_action :require_admin!

    def index
      @connections = Mcp::Connections.new.all
    end

    def destroy
      user = User.find(params[:id])
      Mcp::Connections.new.revoke_for(user)
      redirect_to admin_claude_connections_path, notice: "Accès Claude de #{user.full_name} révoqué."
    end
  end
end
