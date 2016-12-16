module UsersHelper
  def link_to_details(user)
    link_to 'details', account_details_admin_user_path(user)
  end

  def link_to_balance(user)
    link_to 'balance', balance_admin_user_path(user)
  end
end
