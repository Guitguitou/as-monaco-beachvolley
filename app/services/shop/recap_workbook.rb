# frozen_string_literal: true

module Shop
  # Classeur Excel de la clôture : le récap par marque, puis la liste de
  # distribution par membre.
  class RecapWorkbook
    MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def initialize(campaign)
      @campaign = campaign
    end

    def render
      require "axlsx"

      package = Axlsx::Package.new
      sheet("Récap par marque", CampaignRecap.new(@campaign).flat_rows, package)
      sheet("Distribution", DistributionList.new(@campaign).rows, package)
      package.to_stream.read
    end

    private

    def sheet(name, rows, package)
      bold = package.workbook.styles.add_style(b: true)
      package.workbook.add_worksheet(name: name) do |worksheet|
        rows.each_with_index { |row, index| worksheet.add_row(row, style: (bold if index.zero?)) }
      end
    end
  end
end
