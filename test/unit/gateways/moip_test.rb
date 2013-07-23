require 'test_helper'
require 'debugger'

class MoipTest < Test::Unit::TestCase
  def setup
    @gateway = MoipGateway.new(
                 :email => 'name@email.com',
                 :access_token => 'login',
                 :secret => 'password'
               )

    @credit_card = credit_card
    @amount = 1000

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
    @gateway.expects(:ssl_post).returns(successful_authorization_response)
    @gateway.expects(:ssl_get).returns(successful_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response

    assert_equal 156491, response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(successful_authorization_response)
    @gateway.expects(:ssl_get).returns(failed_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private

  # Place raw successful response from gateway here
  def successful_purchase_response
   "({\"Status\":\"EmAnalise\",\"Codigo\":0,\"CodigoRetorno\":\"\",\"TaxaMoIP\":\"74.39\",\"StatusPagamento\":\"Sucesso\",\"Classificacao\":{\"Codigo\":999,\"Descricao\":\"N\xC3\xA3o suportado no ambiente Sandbox\"},\"CodigoMoIP\":156491,\"Mensagem\":\"Requisi\xC3\xA7\xC3\xA3o processada com sucesso\",\"TotalPago\":\"1000.00\"})" 
  end

  def successful_authorization_response
    "<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1=\"http://www.moip.com.br/ws/alpha/\"><Resposta><ID>201307222238491280000004056938</ID><Status>Sucesso</Status><Token>F2M0R173P0W7J2N2W2X2W3K8S4Y9R1A2D8B010D0G0C0I0R4X0X5F6K9G328</Token></Resposta></ns1:EnviarInstrucaoUnicaResponse>"
  end

  # Place raw failed response from gateway here
  def failed_purchase_response
    "({\"StatusPagamentof\": \"Falha\", \"Mensagem\": \"Forma de pagamento invalido.\"})"
  end
end
