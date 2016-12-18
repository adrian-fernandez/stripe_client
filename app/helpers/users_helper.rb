module UsersHelper
  def link_to_details(user)
    link_to user.name, admin_user_path(user)
  end

  def show_available_actions
    available_actions = Import.available_imported_types.map do |x|
      x.to_s.capitalize
    end
    last_imports = Import.get_last_imports

    content_tag(:ul) do
      available_actions.each do |action|
        action_int_value = Import.imported_type_value_for?(action.downcase.to_sym)
        concat(
          content_tag(:li) do
            action
          end
        )
        concat(
          content_tag(:ul) do
            concat(
              content_tag(:li) do
                last_import_date = last_imports[action_int_value].fetch(:created_at) rescue nil
                last_import_date = last_import_date.blank? ? 'Never' : I18n.l(last_import_date)
                concat(
                  content_tag(:strong) do
                    'Last download: '
                  end
                )
                concat(last_import_date)
              end
            )
            last_import_id = last_imports[action_int_value].fetch(:id) rescue nil

            unless last_import_id.blank?
              concat(
                content_tag(:li) do
                  concat(
                    content_tag(:strong) do
                      'Status: '
                    end
                  )
                  concat(Import.get_status_from_value(last_imports[action_int_value].fetch(:status)))
                end
              )
              concat(
                content_tag(:li) do
                  concat(
                    content_tag(:strong) do
                      'Summary: '
                    end
                  )
                  concat("#{last_imports[action_int_value].fetch(:imported_count).to_s}/#{last_imports[action_int_value].fetch(:total_count).to_s} records")
                end
              )
              if last_imports[action_int_value].fetch(:status) == Import.status_value_for?(:done)
                concat(
                  content_tag(:li) do
                    link_to('View', admin_import_path(last_import_id))
                  end
                )
              end
            end
            concat(
              content_tag(:li) do
                link_to('Download new items', download_admin_imports_path(type: action.downcase))
              end
            )
            concat(
              content_tag(:li) do
                link_to('Download all', download_all_admin_imports_path(type: action.downcase))
              end
            )
            unless last_import_id.blank?
              concat(
                content_tag(:li) do
                  link_to('Clean', admin_imports_path(method: :delete))
                end
              )
            end
          end
        )
      end
    end.html_safe
  end

  def show_available_statistics
    content_tag(:ul) do
      concat(
        content_tag(:li) do
          link_to('Per month', data_by_month_admin_imports_path)
        end
      )
      concat(
        content_tag(:li) do
          link_to('Averages in last year', averages_year_admin_imports_path)
        end
      )
    end
  end
end
