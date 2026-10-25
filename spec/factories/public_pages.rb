# frozen_string_literal: true

FactoryBot.define do
  factory :public_page do
    sequence(:title) { |n| "Page #{n}" }
    script_url { "https://script.google.com/macros/s/AKfycbwrJ3CySjPrkCuiSVJ5techDP8phsLmsYRcZeXqjL0IBRrLu_9safD0jD8apNJA76jR/exec" }
  end
end
