class Users::AccountsController < ApplicationController

  def index
  end

  def connect_stripe
    redirect_to current_user.stripe_authorize_url
  end

  def disconnect_stripe
    current_user.unset_stripe_info!
    flash[:message] = "Account disconnected!"
    redirect_to action: :index
  end

  def callback
    if auth_successful?
      begin
        account_info = current_user.stripe_request_access_token(params[:code])
        current_user.set_stripe_info!(account_info)
        flash[:message] = "Account connected!"
      rescue Exception => e
        flash[:message] = "ERROR: #{e.message}"
      end
    else
      flash[:message] = "Error: #{params[:error_description]}"
    end
 
    redirect_to action: :index
  end

  private

  def auth_successful?
    params.has_key?(:code)
  end

end