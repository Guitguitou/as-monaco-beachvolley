# frozen_string_literal: true

# Un joueur en invite un autre à un jeu libre. L'invitation ne réserve pas de
# place : c'est une notification qui mène à la session, où l'invité s'inscrit
# et paie avec ses propres crédits. Un joueur n'est invité qu'une fois par session.
class SessionInvitation < ApplicationRecord
  belongs_to :session
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User"

  validates :invitee_id, uniqueness: { scope: :session_id }
  validate :not_self_invitation

  private

  def not_self_invitation
    errors.add(:invitee, "ne peut pas être toi") if inviter_id == invitee_id
  end
end
