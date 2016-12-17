module ImportsHelper
  def imported_type_str(imported_type)
    Import::IMPORTED_TYPE.key(imported_type).to_s
  end

  def show_elem_line(elem, imported_type)
    text = []
    Import::FIELDS_FOR[Import::IMPORTED_TYPE.key(imported_type)].each do |field|
      text << "<strong>#{field}</strong>: #{elem[:data][field]}"
    end

    text.join(', ').html_safe
  end
end