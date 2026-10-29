# frozen_string_literal: true

module Shop
  # PDF de la clôture : une section par marque avec les quantités par taille,
  # puis la liste de distribution par membre. La police intégrée ne connaît
  # que Windows-1252 : un caractère hors de ce jeu devient « ? ».
  class RecapPdf
    def initialize(campaign)
      @campaign = campaign
    end

    def render
      require "prawn"
      require "prawn/table"
      Prawn::Fonts::AFM.hide_m17n_warning = true # le texte est déjà ramené à Windows-1252

      Prawn::Document.new(page_size: "A4", margin: 36, info: { Title: @campaign.name }).tap do |pdf|
        pdf.font_size(10)
        header(pdf)
        CampaignRecap.new(@campaign).brands.each { |brand| brand_section(pdf, brand) }
        distribution(pdf)
      end.render
    end

    private

    def header(pdf)
      pdf.text printable(@campaign.name), size: 18, style: :bold
      pdf.text "Récap des commandes payées au #{I18n.l(Date.current, format: :long)}", color: "555555"
      pdf.move_down 16
    end

    def brand_section(pdf, brand)
      pdf.text printable("#{brand.name} · #{brand.quantity} articles"), size: 14, style: :bold
      pdf.move_down 6
      rows = brand.rows.map { |row| [ row.product_name, row.color_name, row.cut_label, sizes(row), row.quantity.to_s ] }
      table(pdf, [ [ "Article", "Coloris", "Coupe", "Tailles", "Total" ], *rows ])
      pdf.move_down 16
    end

    def distribution(pdf)
      pdf.start_new_page
      pdf.text "Distribution par membre", size: 14, style: :bold
      pdf.move_down 6
      table(pdf, DistributionList.new(@campaign).rows)
    end

    def sizes(row) = row.sizes.map { |size, qty| "#{size} x#{qty}" }.join("   ")

    def printable(text) = text.to_s.encode("Windows-1252", undef: :replace, invalid: :replace, replace: "?").encode("UTF-8")

    def table(pdf, rows)
      pdf.table(rows.map { |row| row.map { |cell| printable(cell) } }, header: true, width: pdf.bounds.width, cell_style: { size: 9, padding: 5, border_color: "DDDDDD" }) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "F2F1EF"
      end
    end
  end
end
