module UsersHelper
  def link_to_details(user)
    link_to 'details', account_details_admin_user_path(user)
  end

  def link_to_balance(user)
    link_to 'balance', balance_admin_user_path(user)
  end

  def show_available_actions
    available_actions = Import::IMPORTED_TYPE.keys.map do |x|
      x.to_s.capitalize
    end
    last_imports = Import.get_last_imports

    content_tag(:ul) do
      available_actions.each do |action|
        action_int_value = Import::IMPORTED_TYPE[action.downcase.to_sym]
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
                  concat(Import::STATUS.key(last_imports[action_int_value].fetch(:status)))
                end
              )
              concat(
                content_tag(:li) do
                  concat(
                    content_tag(:strong) do
                      'Summary: '
                    end
                  )
                  concat(last_imports[action_int_value].fetch(:total_count).to_s + ' records')
                end
              )
              if last_imports[action_int_value].fetch(:status) == Import::STATUS[:done]
                concat(
                  content_tag(:li) do
                    link_to('View', view_admin_import_path(last_import_id))
                  end
                )
              end
            end
            concat(
              content_tag(:li) do
                link_to('Download', download_admin_imports_path(type: action.downcase))
              end
            )
          end
        )
      end
    end.html_safe

  end
end
