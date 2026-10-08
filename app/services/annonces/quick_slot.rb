# frozen_string_literal: true

module Annonces
  # Créneaux prêts à l'emploi de « Tu es libre quand ? » : un joueur choisit
  # un moment en un tap, sans remplir de formulaire.
  #
  #   Annonces::QuickSlot.available               # ceux qui sont encore à venir
  #   Annonces::QuickSlot.find("samedi_matin")    # nil si inconnu ou passé
  class QuickSlot
    Preset = Struct.new(:key, :label, :day, :hour, keyword_init: true)

    DURATION = 2.hours
    # Un créneau disparaît quand il commence dans moins de ce délai : plus le
    # temps de réunir des joueurs.
    MIN_NOTICE = 2.hours
    WEEKLY_DAYS = %i[saturday sunday].freeze

    PRESETS = [
      Preset.new(key: "ce_soir", label: "Ce soir", day: :today, hour: 19),
      Preset.new(key: "demain_soir", label: "Demain soir", day: :tomorrow, hour: 19),
      Preset.new(key: "samedi_matin", label: "Samedi matin", day: :saturday, hour: 10),
      Preset.new(key: "dimanche_matin", label: "Dimanche matin", day: :sunday, hour: 10)
    ].freeze

    attr_reader :key, :label, :start_at, :end_at

    def self.available(now: Time.current)
      PRESETS.map { |preset| new(preset, now: now) }.select(&:bookable?)
    end

    def self.find(key, now: Time.current)
      available(now: now).find { |quick_slot| quick_slot.key == key.to_s }
    end

    def initialize(preset, now:)
      @key = preset.key
      @label = preset.label
      @now = now
      @start_at = start_for(preset)
      @end_at = @start_at + DURATION
    end

    def bookable?
      start_at - MIN_NOTICE > now
    end

    private

    attr_reader :now

    # Samedi et dimanche : le prochain, aujourd'hui compris s'il est encore temps.
    def start_for(preset)
      start = day_for(preset.day).in_time_zone.change(hour: preset.hour)
      WEEKLY_DAYS.include?(preset.day) && start - MIN_NOTICE <= now ? start + 7.days : start
    end

    def day_for(day)
      today = now.to_date
      case day
      when :today then today
      when :tomorrow then today + 1
      else today + ((Date::DAYNAMES.index(day.to_s.capitalize) - today.wday) % 7)
      end
    end
  end
end
