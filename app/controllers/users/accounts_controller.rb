class Users::AccountsController < ApplicationController

  def index
    #@account = Account.first
  end

  def connect_stripe
    account = StripeApi.new
    account.connect

    redirect_to account.authorize_url
  end

  def callback

  end

end