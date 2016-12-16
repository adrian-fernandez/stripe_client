require 'stripe'
module StripeApi
  @@config = nil

  def self.authorize_url
    StripeApi.connect
    StripeApi.config[:client].auth_code.authorize_url(StripeApi.request_params)
  end

  def self.request_access_token(code)
    StripeApi.connect
    StripeApi.config[:client].auth_code.get_token(code, StripeApi.request_params)
  end

  def self.get_balance
    StripeApi.set_api_key
    Stripe::Balance.retrieve
  end

  def self.list_balances
    StripeApi.set_api_key
    Stripe::BalanceTransaction.all(limit: 3)
  end

  private

  def self.load_config
    config_file = YAML::load(File.open([Rails.root,'config','stripe.yml'].join('/')))
    @@config = {}
    @@config[:api_key] = config_file['api_key']
    @@config[:client_id] = config_file['client_id']

    @@config[:options] = { site: 'https://connect.stripe.com',
                           authorize_url: '/oauth/authorize',
                           token_url: '/oauth/token' }
    @@config
  end

  def self.config
    @@config ||= StripeApi.load_config
  end

  def self.connect
    StripeApi.config[:client] ||= OAuth2::Client.new(StripeApi.config[:client_id],
                                                     StripeApi.config[:api_key],
                                                     StripeApi.config[:options])
  end

  def self.set_api_key
    Stripe.api_key = StripeApi.config[:api_key]
  end

  def self.request_params
    { scope: 'read_only' }
  end
end
