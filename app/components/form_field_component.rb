# frozen_string_literal: true

class FormFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    attribute:,
    type: :text_field,
    required: false,
    label: nil,
    show_label: true,
    options: nil,
    select_options: nil,
    html_options: nil,
    input_class: nil
  )
    @form = form
    @attribute = attribute
    @type = type
    @required = required
    @label = label
    @show_label = show_label
    @options = options
    @select_options = select_options
    @html_options = html_options || {}
    @input_class = input_class
  end

  def label_text
    return @label if @label.present?

    if @form.object.respond_to?(:class) && @attribute.is_a?(Symbol)
      return @form.object.class.human_attribute_name(@attribute)
    end

    @attribute.to_s.humanize
  end

  def field_id
    return @html_options[:id].to_s if @html_options[:id].present?

    if @form.object_name.present?
      return "#{@form.object_name}_#{sanitized_attribute_for_dom_id}"
    end

    sanitized_attribute_for_dom_id
  end

  def field_classes
    base = @input_class.present? ? @input_class.to_s : default_base_input_class_for_type
    base = [base, error_input_class].compact.join(" ") if has_error?
    caller_class = @html_options[:class].to_s
    [base, caller_class.presence].compact.join(" ")
  end

  def error_message
    return nil unless errors_present?

    @form.object.errors[@attribute].first
  end

  def has_error?
    return false unless errors_present?

    @form.object.errors[@attribute].any?
  end

  def select_options_hash
    opts = @select_options.presence ? @select_options.dup : {}
    # Required select must have a blank/placeholder option so validation can force a real choice.
    opts[:include_blank] = true if @required && (opts[:include_blank].nil? || opts[:include_blank] == false)
    opts[:include_blank] = !@required if opts[:include_blank].nil?
    opts
  end

  private

  def default_base_input_class_for_type
    case @type.to_sym
    when :select
      "block w-full rounded-none border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-asmbv-red focus:ring-2 focus:ring-asmbv-red sm:text-sm"
    when :number_field, :datetime_local_field, :date_field
      "block w-full rounded-none border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-asmbv-red focus:ring-2 focus:ring-asmbv-red sm:text-sm"
    when :color_field, :file_field
      # Callers should provide `input_class` for these.
      ""
    else
      "block w-full rounded-none border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder:text-gray-400 focus:border-asmbv-red focus:ring-2 focus:ring-asmbv-red sm:text-sm"
    end
  end

  def error_input_class
    "border-red-600 focus:border-red-600 focus:ring-red-600"
  end

  def errors_present?
    @form.object.respond_to?(:errors)
  end

  def sanitized_attribute_for_dom_id
    @attribute.to_s
              .gsub("][", "_")
              .tr("[]", "_")
              .gsub(/_{2,}/, "_")
              .gsub(/\A_+|_+\z/, "")
  end
end
