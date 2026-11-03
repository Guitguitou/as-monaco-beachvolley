# frozen_string_literal: true

require "net/http"
require "resolv"

module Mcp
  # Télécharge une photo d'article depuis une URL donnée à Claude. Seulement
  # en https, vers une adresse publique (pas de requête vers le réseau interne),
  # sans suivre les redirections, et dans la limite d'une image de 10 Mo.
  class PhotoDownload
    MAX_BYTES = 10.megabytes
    CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    TIMEOUT = 10

    Photo = Data.define(:io, :filename, :content_type)

    def initialize(url, resolver: Resolv)
      @uri = URI.parse(url.to_s)
      @resolver = resolver
    rescue URI::InvalidURIError
      raise ArgumentError, "URL de photo invalide : #{url}"
    end

    def call
      raise ArgumentError, "La photo doit être une URL https." unless @uri.is_a?(URI::HTTPS) && @uri.host.present?

      response, body = fetch(public_address)
      raise ArgumentError, "Photo inaccessible (HTTP #{response.code})." unless response.is_a?(Net::HTTPSuccess)

      Photo.new(io: StringIO.new(body), filename: filename, content_type: content_type(response))
    end

    private

    def public_address
      address = @resolver.getaddress(@uri.host)
      ip = IPAddr.new(address)
      raise ArgumentError, "Adresse de photo non autorisée." if ip.private? || ip.loopback? || ip.link_local?

      address
    rescue Resolv::ResolvError, IPAddr::InvalidAddressError
      raise ArgumentError, "Hôte de photo introuvable : #{@uri.host}"
    end

    # Renvoie la réponse et son corps, lu par morceaux pour s'arrêter dès 10 Mo.
    def fetch(address)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.ipaddr = address
      http.use_ssl = true
      http.open_timeout = http.read_timeout = TIMEOUT
      body = +""
      response = http.request_get(@uri.request_uri) do |chunked|
        chunked.read_body do |chunk|
          body << chunk
          raise ArgumentError, "Photo trop lourde (10 Mo au plus)." if body.bytesize > MAX_BYTES
        end
      end
      [ response, body ]
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise ArgumentError, "Photo inaccessible : #{e.message}"
    end

    def content_type(response)
      type = response.content_type.to_s
      raise ArgumentError, "Le fichier n'est pas une image (#{type.presence || 'type inconnu'})." unless CONTENT_TYPES.include?(type)

      type
    end

    def filename = File.basename(@uri.path).presence || "photo"
  end
end
