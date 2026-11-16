# frozen_string_literal: true

# Contrôle de 15h : annule les entraînements du jour qui n'ont pas encore
# commencé et comptent moins de 2 inscrits confirmés, avec le motif « Moins de
# 2 inscrits ». Les inscrits sont remboursés et prévenus (cf. GLOSSARY.md,
# « Séance annulée »).
class CancelUnderfilledTrainingsJob < ApplicationJob
  queue_as :default

  MIN_PLAYERS = 2

  def perform
    underfilled_trainings.each do |session|
      Sessions::CancelSessionService.call(session:, reason: :moins_de_2_inscrits)
      Rails.logger.info("[Contrôle 15h] session #{session.id} annulée : moins de #{MIN_PLAYERS} inscrits")
    end
  end

  private

  def underfilled_trainings
    confirmed_counts = Registration.confirmed.group(:session_id).count
    Session.trainings.held.where(start_at: Time.current..Time.current.end_of_day)
           .reject { |session| confirmed_counts.fetch(session.id, 0) >= MIN_PLAYERS }
  end
end
