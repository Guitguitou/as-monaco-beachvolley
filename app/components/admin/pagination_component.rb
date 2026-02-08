# frozen_string_literal: true

module Admin
  class PaginationComponent < ViewComponent::Base
    attr_reader :current_page, :total_pages, :params

    def initialize(current_page:, total_pages:, params:)
      @current_page = current_page.to_i
      @total_pages = total_pages.to_i
      @params = params
    end

    def pages
      window = 2
      pages = [1, total_pages]
      range_start = [current_page - window, 1].max
      range_end = [current_page + window, total_pages].min
      pages += (range_start..range_end).to_a
      pages.uniq.sort
    end

    def page_link(page)
      base_params = params.to_unsafe_h.except("controller", "action", "utf8", "commit")
      helpers.url_for(base_params.merge(page: page))
    end
  end
end

