# frozen_string_literal: true

# Photo de profil : une image raisonnable, pas n'importe quel fichier.
class AvatarValidator < ActiveModel::EachValidator
  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SIZE = 5.megabytes

  def validate_each(record, attribute, attachment)
    return unless attachment.attached?

    blob = attachment.blob
    record.errors.add(attribute, "doit être une image JPEG, PNG ou WebP") unless CONTENT_TYPES.include?(blob.content_type)
    record.errors.add(attribute, "ne doit pas dépasser 5 Mo") if blob.byte_size > MAX_SIZE
  end
end
