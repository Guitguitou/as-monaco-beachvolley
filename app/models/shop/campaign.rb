# frozen_string_literal: true

module Shop
  # Campagne de commande groupée (cf. GLOSSARY.md). Les membres commandent
  # tant qu'elle est ouverte et que le jour est dans sa période : passé la
  # date de clôture, elle n'accepte plus rien, même sans changer de statut.
  class Campaign < ApplicationRecord
    enum :status, { draft: "draft", open: "open", closed: "closed" }, suffix: true

    validates :name, :opens_on, :closes_on, presence: true
    validates :closes_on, comparison: { greater_than_or_equal_to: :opens_on }, if: -> { opens_on && closes_on }

    scope :ordered, -> { order(opens_on: :desc) }
    scope :accepting_orders, ->(on: Date.current) { open_status.where(opens_on: ..on, closes_on: on..) }

    def self.for_members(on: Date.current) = accepting_orders(on: on).order(:closes_on).first

    # La boutique est réservée aux licenciés à jour (licence payée, cf. GLOSSARY.md).
    def self.for_member(user, on: Date.current) = (for_members(on: on) if user&.activated?)

    def accepting_orders?(on: Date.current) = open_status? && (opens_on..closes_on).cover?(on)
  end
end
