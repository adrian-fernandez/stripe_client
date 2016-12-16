class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:balance, :account_details]

  def index
    @users_with_stripe = User.with_stripe_account
  end

  def balance
    if params[:update].present?
      @user.set_balance!(StripeApi.get_balance.to_json)
    end
  end

  def account_details
  end

  private

  def set_user
    @user = User.find_by_id(params[:id])
  end
end