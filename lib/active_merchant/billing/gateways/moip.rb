require File.dirname(__FILE__) + '/moip/authorization_request'
require File.dirname(__FILE__) + '/moip/complete_purchase'

module  ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class MoipGateway < Gateway

      self.test_url = 'https://desenvolvedor.moip.com.br/sandbox'
      self.live_url = 'https://www.moip.com.br'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['BR']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.moip.com.br/'

      # The name of the gateway
      self.display_name = 'Moip'

      def initialize(options = {})
        requires!(options, :email, :access_token, :secret)

        @merchant_email = options[:email]
        @access_token   = options[:access_token]
        @secret         = options[:secret]

        super
      end

      def purchase(money, creditcard, options = {})
        options.update({merchant_email: @merchant_email})

        authorization = MoipCore::AuthorizationRequest.new(self, money, options).request
        return failed_response(authorization) unless authorization.success?

        complete = MoipCore::CompletePurchase.new(self, creditcard, authorization.token).request

        Response.new(complete.success?, complete.message, complete.response, :test => test?, :authorization => complete.moip_code)
      end

      def failed_response(authorization)
        Response.new(authorization.success?, authorization.error_message, authorization.response, :test => test?)
      end

      def url
        test? ? test_url : live_url
      end

      def basic_auth
        'Basic ' + ["#{@options[:access_token]}:#{@options[:secret]}"].pack('m').delete("\r\n")
      end

      private

      def complete_purchase(token, creditcard)
      end

    end
  end
end