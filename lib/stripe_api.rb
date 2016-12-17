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
    StripeApi.setup
    Stripe::Balance.retrieve
  end

  def self.list_balances
    StripeApi.setup
    Stripe::BalanceTransaction.all(limit: 3)
  end

  def self.import(import_type, from, last_id = nil)
    puts "IMPORT_TYPE = #{import_type}"
    puts "api_class(import_type) = #{api_class(import_type)}"
    StripeApi.do_import(api_class(import_type), from, last_id)
  end

  private

  def self.do_import(class_name, from, last_id = nil)
    StripeApi.setup

    params = { 'include[]': 'total_count' }
    # NOTE: Used to test recurrent calling to get all when limit < total_count
    # params['limit'] = 1
    params['created'] = { 'gte': from.to_i }
    params['starting_after'] = last_id unless last_id.nil?

    response = class_name.list(params)

    { data: response['data'],
      total_count: response['total_count'],
      has_more: response['has_more'],
      last_id: response['data'].blank? ? nil : response['data'].last.id
    }
  end

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

  def self.setup
    StripeApi.set_api_key
  end

  def self.set_api_key
    Stripe.api_key = StripeApi.config[:api_key]
  end

  def self.request_params
    { scope: 'read_only' }
  end

  def self.api_class(import_type)
    case Import::IMPORTED_TYPE.key(import_type)
    when :charges
      Stripe::Charge
    when :disputes
      Stripe::Dispute
    end
  end
end
