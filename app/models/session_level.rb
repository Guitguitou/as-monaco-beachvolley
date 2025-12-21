# frozen_string_literal: true

class SessionLevel < ApplicationRecord
  belongs_to :session
  belongs_to :level
end
