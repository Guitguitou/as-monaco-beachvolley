# frozen_string_literal: true

require "net/http"

module PublicPages
  # Lit le titre et les balises Open Graph de la web app Google Apps Script.
  # Les robots d'aperçu (WhatsApp…) ne lisent que notre page, pas l'iframe :
  # on recopie donc ces métadonnées chez nous. En cas d'échec, rien n'est repris.
  class FetchMeta
    MAX_REDIRECTS = 3
    TIMEOUT = 5

    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def call(url)
      parse(fetch(URI(url)))
    rescue StandardError => error
      logger.warn("[PublicPages] Métadonnées illisibles pour #{url} : #{error.message}")
      {}
    end

    private

    attr_reader :logger

    def fetch(uri, redirects = MAX_REDIRECTS)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.get(uri.request_uri)
      end
      return response.body.to_s.dup.force_encoding(Encoding::UTF_8) unless response.is_a?(Net::HTTPRedirection)
      raise "trop de redirections" if redirects.zero?

      fetch(URI.join(uri, response["location"]), redirects - 1)
    end

    def parse(html)
      document = Nokogiri::HTML(html)
      {
        meta_title: meta(document, "og:title") || document.at("title")&.text,
        meta_description: meta(document, "og:description") || meta(document, "description"),
        meta_image: meta(document, "og:image")
      }.transform_values { |value| value&.strip.presence }
    end

    def meta(document, key)
      document.at(%(meta[property="#{key}"], meta[name="#{key}"]))&.[]("content")
    end
  end
end
