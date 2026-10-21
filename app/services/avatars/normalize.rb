# frozen_string_literal: true

module Avatars
  # Réduit la photo de profil envoyée avant de la stocker : 1024 px au plus
  # grand côté, en WebP. Une photo de téléphone (3 à 5 Mo) tombe autour de
  # 100 Ko, ce qui ménage le quota Cloudinary et la bande passante des listes.
  #
  # 1024 px suffisent : l'avatar le plus grand fait 128 px, zoom ×3 et écran
  # retina compris. Le cadrage étant stocké en pourcentages, il reste valable.
  #
  # Un fichier qui n'est pas une image acceptée est rendu tel quel :
  # AvatarValidator le refusera avec un message clair.
  class Normalize
    MAX_DIMENSION = 1024
    QUALITY = 80
    MAX_UPLOAD_SIZE = 15.megabytes

    def initialize(upload, processor: ImageProcessing::MiniMagick)
      @upload = upload
      @processor = processor
    end

    def call
      return upload unless processable?

      {
        io: processor.source(upload.path)
                     .auto_orient
                     .strip
                     .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
                     .convert("webp")
                     .saver(quality: QUALITY)
                     .call,
        filename: "#{File.basename(upload.original_filename.to_s, '.*').presence || 'avatar'}.webp",
        content_type: "image/webp"
      }
    rescue MiniMagick::Error, ImageProcessing::Error
      upload
    end

    private

    attr_reader :upload, :processor

    def processable?
      upload.respond_to?(:path) &&
        AvatarValidator::CONTENT_TYPES.include?(upload.content_type) &&
        upload.size <= MAX_UPLOAD_SIZE
    end
  end
end
