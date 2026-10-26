# frozen_string_literal: true

# Une fin qui ne précède pas son début :
#   validates :ends_on, after: { start: :starts_on, allow_equal: true, message: "…" }
# Sans `allow_equal`, la fin doit être strictement après le début.
class AfterValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, finish)
    start = record.public_send(options.fetch(:start))
    return if start.blank? || finish.blank?
    return if finish > start || (options[:allow_equal] && finish == start)

    record.errors.add(attribute, options.fetch(:message))
  end
end
