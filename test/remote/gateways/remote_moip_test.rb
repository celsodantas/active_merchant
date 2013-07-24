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
    @options[:billing_address][:state] = nil

    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Estado de endereço deverá ser enviado obrigatoriamente', response.message
  end

  def test_invalid_login
    gateway = MoipGateway.new(
                :access_token => 'nnn',
                :secret => 'nnn',
                :email => 'nnn'
              )

    assert_raise ActiveMerchant::ResponseError do
      gateway.purchase(@amount, @credit_card, @options)
    end
  end
end
