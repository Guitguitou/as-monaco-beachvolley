# frozen_string_literal: true

require "rails_helper"

# ADR 0001 : angles droits partout. Seuls `rounded-none` (contrôles, surfaces)
# et `rounded-full` (avatars, badges, pastilles) sont autorisés.
RSpec.describe "Politique de rayon (ADR 0001)" do
  let(:forbidden_radius) { /(?<![\w-])rounded(?:-(?:sm|md|lg|xl|2xl|3xl|t-[\w]+|b-[\w]+|l-[\w]+|r-[\w]+))?(?![\w-])/ }

  it "n'utilise que rounded-none et rounded-full dans les vues et composants" do
    files = Dir[Rails.root.join("app/{views,components}/**/*.{erb,rb}")]
    offenses = files.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{path.delete_prefix("#{Rails.root}/")}:#{index + 1}" if line.match?(forbidden_radius)
      end
    end

    expect(offenses).to be_empty, "Rayons interdits :\n#{offenses.join("\n")}"
  end
end
