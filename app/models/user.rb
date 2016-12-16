class User < ActiveRecord::Base
  scope :with_stripe_account, -> { where.not(stripe_access_token: '') }

  def set_stripe_info!(data)
    update_attribute(:stripe_info, data.to_json)
    update_attribute(:stripe_access_token, data.token)
  end

  def unset_stripe_info!
    update_attribute(:stripe_info, '')
    update_attribute(:stripe_access_token, '')
  end

  def stripe_account_connected?
    !stripe_access_token.blank?
  end

  def set_balance!(data)
    update_attribute(:balance, data.to_json)
    update_attribute(:balance_updated_at, Time.zone.now)
    true
  end
end