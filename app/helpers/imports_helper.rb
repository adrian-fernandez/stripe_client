module ImportsHelper
  def imported_type_str(imported_type)
    Import.get_imported_type_from_value(imported_type).to_s
  end

  def link_view_full(id, imported_type)
    link_to('View full',
            show_full_data_admin_imports_path(id: id, type: imported_type),
            remote: true,
            class: 'link_full_data',
            'data-div': id)
  end

  def link_hide_view_full(id, imported_type)
    link_to('Hide details',
            '#',
            class: 'link_hide_full_data',
            style: 'display: none;',
            'data-div': id)
  end

  def show_elem_line(elem, imported_type)
    text = []
    Import.fields_for(Import.get_imported_type_from_value(imported_type)).each do |field|
      if field == 'created'
        text << "<strong>#{field}</strong>: #{I18n.l(DateTime.strptime(elem[:data][field].to_s, '%s'))}"
      else
        text << "<strong>#{field}</strong>: #{elem[:data][field]}"
      end
    end

    id = elem[:data]['id']
    view_full = " (<span id='action-btn-#{id}'>#{link_view_full(id, imported_type)}#{link_hide_view_full(id, imported_type)}</span>)"

    text.join(', ').concat(view_full).html_safe
  end

  def display_amount(amount)
    amount != 0 ? number_to_currency(amount / 100.0, unit: '€', format: '%n %u', separator: ',') : 0
  end

  def check_charges_and_transfers_msg
    errors = []

    errors << 'No charges were found, you should download it' unless Import.data_downloaded_for?(:charges, current_user.id)
    errors << 'No transfers were found, you should download it' unless Import.data_downloaded_for?(:transfers, current_user.id)

    errors.blank? ? '' : "<div>#{errors.join('<br/>')}</div>".html_safe
  end

  def chart(container, data, field, field_correction_factor, title, label, legend, sufix)
    chart_data = []
    series = []
    data_years = data.fetch(:years, [DateTime.now.year])

    data_years.each do |year|
      field.map do |f|
        if data.fetch(:years, nil).nil?
          chart_data << (1..12).map{|month| (data.fetch(month, {}).fetch(f, 0.0).to_f / field_correction_factor)}.join(',')
        else
          chart_data << (1..12).map{|month| (data.fetch(month, {}).fetch(year, {}).fetch(f, 0.0).to_f / field_correction_factor)}.join(',')
        end
      end
    end

    i = 0
    aux = 0
    chart_data.each do |year_data|
      series << "{ name: '#{legend[aux]} #{data_years[i]}', data: [#{year_data}] }"
      aux += 1

      if aux == field.count
        i += 1 
        aux = 0
      end
    end

    "$(function () { Highcharts.chart('#{container}', {"\
      "title: {"\
          "text: '#{title}',"\
          "x: -20"\
        "},"\
          "xAxis: {"\
              "categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',"\
                  "'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']"\
          "},"\
          "yAxis: {"\
              "title: {"\
                  "text: '#{label}'"\
              "},"\
              "plotLines: [{"\
                  "value: 0,"\
                  "width: 1,"\
                  "color: '#808080'"\
              "}]"\
          "},"\
          "tooltip: {"\
              "valueSuffix: '#{sufix}'"\
          "},"\
          "legend: {"\
              "layout: 'vertical',"\
              "align: 'right',"\
              "verticalAlign: 'middle',"\
              "borderWidth: 0"\
          "},"\
          "series: [#{series.join(',').html_safe}]"\
      "})});".html_safe
  end
end