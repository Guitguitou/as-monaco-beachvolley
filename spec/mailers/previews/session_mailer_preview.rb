# frozen_string_literal: true

# Previews accessibles sur http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  def promoted_to_main_list
    SessionMailer.promoted_to_main_list(preview_user, preview_session)
  end

  def session_cancelled
    SessionMailer.session_cancelled(
      preview_user,
      session_name: "Tournoi été",
      session_date: "20/07/2026"
    )
  end

  private

  def preview_user
    User.first || begin
      user = User.new(
        first_name: "Bob",
        last_name: "Preview",
        email: "preview@example.com"
      )
      user.id = 1
      user
    end
  end

  def preview_session
    Session.first || begin
      session = Session.new(
        title: "Jeu libre du soir",
        session_type: "jeu_libre",
        start_at: Time.zone.local(Date.current.year, 6, 15, 19, 30),
        end_at: Time.zone.local(Date.current.year, 6, 15, 21, 0),
        terrain: "Terrain 1",
        max_players: 12,
        user: preview_user
      )
      session.id = 1
      session
    end
  end
end
