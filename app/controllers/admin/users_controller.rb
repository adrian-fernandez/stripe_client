class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:balance, :show]

  def index
    @users_with_stripe = User.with_stripe_account
  end

  def show
  end

  private

  def set_user
    @user = User.find_by_id(params[:id])
  end
end