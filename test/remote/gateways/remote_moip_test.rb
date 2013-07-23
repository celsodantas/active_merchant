#encoding: utf-8

require 'test_helper'
require 'debugger'

class RemoteMoipTest < Test::Unit::TestCase


  def setup
    @gateway = MoipGateway.new(fixtures(:moip))

    @amount = 1000
    @credit_card = credit_card('4000100011112224')
    @declined_card = credit_card('4000300011112220')

    # needed for brazilian gateway
    brazilian_address = address({
      state: "BA",
      email: "joao.da.silva@gmail.com",
      country: "BRA",
      zip: "41800-100",
      number: "522",
      neighborhood: "Barra"
    })

    @options = {
      :order_id => "1-#{rand}",
      :billing_address => brazilian_address,
      :description => 'Store Purchase',
      :reason => "because it's cool.",
    }
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Requisição processada com sucesso', response.message
  end

  def test_unsuccessful_purchase
    # TODO find a way that the moip sandbox denies the credit card or any other information
    @declined_card.number = ""
    @declined_card.verification_value

    assert response = @gateway.purchase(@amount, @declined_card, @options)
    debugger
    assert_failure response
    assert_equal 'REPLACE WITH FAILED PURCHASE MESSAGE', response.message
  end

  # def test_authorize_and_capture
  #   amount = @amount
  #   assert auth = @gateway.authorize(amount, @credit_card, @options)
  #   assert_success auth
  #   assert_equal 'Success', auth.message
  #   assert auth.authorization
  #   assert capture = @gateway.capture(amount, auth.authorization)
  #   assert_success capture
  # end

  # def test_failed_capture
  #   assert response = @gateway.capture(@amount, '')
  #   assert_failure response
  #   assert_equal 'REPLACE WITH GATEWAY FAILURE MESSAGE', response.message
  # end

  # def test_invalid_login
  #   gateway = MoipGateway.new(
  #               :login => '',
  #               :password => ''
  #             )
  #   assert response = gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert_equal 'REPLACE WITH FAILURE MESSAGE', response.message
  # end
end
