# frozen_string_literal: true

module Admin
  class TableComponent < ViewComponent::Base
    def initialize(class: nil)
      @class = binding.local_variable_get(:class)
    end

    def classes
      ["overflow-x-auto border border-gray-200 shadow-sm", @class].compact.join(" ")
    end
  end
end

