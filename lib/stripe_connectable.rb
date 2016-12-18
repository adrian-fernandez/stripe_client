require 'stripe'
module StripeConnectable
  attr_accessor :_stripe_config

  def stripe_config
    _stripe_config ||= stripe_load_config
  end

  def stripe_authorize_url
    stripe_connect
    stripe_config[:client].auth_code.authorize_url(stripe_request_params)
  end

  def stripe_request_access_token(code)
    stripe_connect
    stripe_config[:client].auth_code.get_token(code, stripe_request_params)
  end

  def stripe_import(import_type, from, last_id = nil)
    stripe_setup
    stripe_do_import(stripe_api_class(import_type), from, last_id)
  end

  # Retrieve full data of an object
  def stripe_retrieve(id, import_type)
    stripe_setup
    class_name = stripe_api_class(import_type)
    class_name.retrieve(id)
  end

  private

  # Must be called from import
  def stripe_do_import(class_name, from, last_id = nil)
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

  def stripe_load_config
    template = ERB.new File.new(File.expand_path('../../config/stripe.yml', __FILE__)).read
    yaml_config = YAML.load template.result(s)

    self._stripe_config ||= {}
    self._stripe_config[:options] = { site: 'https://connect.stripe.com',
                                      authorize_url: '/oauth/authorize',
                                      token_url: '/oauth/token' }
    self._stripe_config[:client_id] = yaml_config['client_id']
    self._stripe_config[:api_key] = yaml_config['api_key']

    self._stripe_config
  end

  def stripe_connect
    stripe_load_config
    _stripe_config[:client] ||= OAuth2::Client.new(ENV.fetch('stripe_api_key'),
                                                   ENV.fetch('stripe_client_id'),
                                                   stripe_config[:options])
  end

  def stripe_setup
    stripe_set_api_key
  end

  def stripe_set_api_key
    Stripe.api_key = stripe_access_token
  end

  def stripe_request_params
    { scope: 'read_only' }
  end

  def stripe_api_class(import_type)
    type_name = Import.get_imported_type_from_value(import_type.to_i)
    fail "Import type not found: #{import_type}" if type_name.blank?

    case type_name
    when :charges
      Stripe::Charge
    when :transfers
      Stripe::Transfer
    when :disputes
      Stripe::Dispute
    when :refunds
      Stripe::Refund
    when :bankaccounts
      Stripe::BankAccount
    when :orders
      Stripe::Order
    when :returns
      Stripe::OrderReturn
    when :subscriptions
      Stripe::Subscription
    else
      fail "API Class not found: #{type_name}"
    end
  end
end
