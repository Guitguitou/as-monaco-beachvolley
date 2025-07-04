# frozen_string_literal: true

class FormFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    attribute:,
    type: :text_field,
    required: false,
    options: nil,
    as: nil
  )
    @form = form
    @attribute = attribute
    @type = type
    @required = required
    @options = options
    @as = as # for select and radio groups
  end

  def label_text
    @form.object.class.human_attribute_name(@attribute)
  end

  def field_id
    "#{@form.object_name}_#{@attribute}"
  end

  def field_classes
    base = "fr-input w-full"
    error = @form.object.errors[@attribute].any? ? "fr-input--error border-red-500" : ""
    "#{base} #{error}"
  end

  def error_message
    @form.object.errors[@attribute].first
  end

  def has_error?
    @form.object.errors[@attribute].any?
  end
end
