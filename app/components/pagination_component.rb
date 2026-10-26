# frozen_string_literal: true

# Pagination numérotée d'un tableau (première, dernière et deux pages autour
# de la page courante), à partir d'un objet Pagination.
#
#   render PaginationComponent.new(pagination: page, url_for: ->(n) { admin_users_path(page: n) })
class PaginationComponent < ApplicationComponent
  WINDOW = 2
  LINK = "inline-flex items-center justify-center min-w-8 h-8 px-2 rounded-none border border-gray-300 bg-white hover:bg-gray-50"
  CURRENT = "inline-flex items-center justify-center min-w-8 h-8 px-2 rounded-none bg-brand text-white font-semibold"
  DISABLED = "inline-flex items-center justify-center min-w-8 h-8 px-2 rounded-none border border-gray-200 text-gray-300"

  def initialize(pagination:, url_for:)
    @pagination = pagination
    @url_for = url_for
  end

  def render? = @pagination.multiple_pages?

  private

  attr_reader :pagination

  def url(page) = @url_for.call(page)

  # Numéros affichés, avec nil là où des pages sont sautées (« … »).
  def pages
    current = pagination.current_page
    numbers = ([ 1, pagination.total_pages ] + ((current - WINDOW)..(current + WINDOW)).to_a)
              .select { |page| page.between?(1, pagination.total_pages) }.uniq.sort
    numbers.each_cons(2).flat_map { |page, following| following - page > 1 ? [ page, nil ] : [ page ] } + [ numbers.last ]
  end
end
