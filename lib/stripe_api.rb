class StripeApi
  attr_accessor :api_key, :client_id, :options
  attr_accessor :client

  def initialize
    config = YAML::load(File.open([Rails.root,'config','stripe.yml'].join('/')))
    @api_key = config['api_key']
    @client_id = config['client_id']

    @options = { site: 'https://connect.stripe.com',
                authorize_url: '/oauth/authorize',
                token_url: '/oauth/token' }
  end

  def connect
    @client = OAuth2::Client.new(@client_id, @api_key, @options)
  end

  def authorize_url
    params = { scope: 'read_only' }
    @client.auth_code.authorize_url(params)
  end
end
