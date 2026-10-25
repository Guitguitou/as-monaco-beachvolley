# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModalComponent, type: :component do
  it "rend un dialog titré qui garde ses attributs data" do
    render_inline(described_class.new(title: "Confirmer", data: { late_removal_target: "dialog" })) { "Contenu" }

    expect(page).to have_css("dialog[data-late-removal-target='dialog'].rounded-none", visible: :all)
    expect(page).to have_css("dialog h3", text: "Confirmer", visible: :all)
    expect(page).to have_css("dialog", text: "Contenu", visible: :all)
  end

  it "affiche les actions quand elles sont fournies" do
    render_inline(described_class.new(title: "Confirmer")) do |modal|
      modal.with_actions { "Valider" }
    end

    expect(page).to have_css("dialog .space-y-2", text: "Valider", visible: :all)
  end
end
