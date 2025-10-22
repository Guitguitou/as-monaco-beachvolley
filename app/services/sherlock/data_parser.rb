module Sherlock
  module DataParser
    module_function

    # "k=v|k=v|..." -> { "k" => "v", ... }
    def parse(data_string)
      return {} if data_string.blank?

      Hash[
        data_string.split("|").map do |pair|
          k, v = pair.split("=", 2)
          [k, v]
        end
      ]
    end
  end
end
