# frozen_string_literal: true

module Mcp
  # Connexions Claude actives, une par utilisateur : quand il a connecté son
  # Claude et quand le jeton a été renouvelé pour la dernière fois (le refresh
  # token tourne à chaque usage, cf. Mcp::ExpireIdleTokensJob).
  class Connections
    Connection = Struct.new(:user, :connected_at, :last_used_at, :scopes, keyword_init: true)

    def all
      tokens_by_user = active_tokens.group_by(&:resource_owner_id)
      users = User.where(id: tokens_by_user.keys).index_by(&:id)

      tokens_by_user.map do |user_id, tokens|
        Connection.new(
          user: users.fetch(user_id),
          connected_at: first_grant_at(user_id),
          last_used_at: tokens.map(&:created_at).max,
          scopes: tokens.flat_map { |token| token.scopes.to_a }.uniq
        )
      end.sort_by { |connection| -connection.last_used_at.to_i }
    end

    def revoke_for(user)
      Doorkeeper::AccessToken.where(resource_owner_id: user.id, revoked_at: nil).find_each(&:revoke)
    end

    private

    def active_tokens
      Doorkeeper::AccessToken.where(revoked_at: nil).to_a
    end

    def first_grant_at(user_id)
      Doorkeeper::AccessGrant.where(resource_owner_id: user_id).minimum(:created_at)
    end
  end
end
