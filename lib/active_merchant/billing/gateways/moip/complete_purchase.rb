module  ActiveMerchant #:nodoc:
  module Billing #:nodoc
    module MoipCore #:nodoc

      class CompletePurchase
        attr_reader :response

        def initialize(gateway, creditcard, token)
          @gateway    = gateway
          @creditcard = creditcard
          @token      = token
        end

        def request
          parameters = build_json(@creditcard)
          @response_raw = @gateway.ssl_get("#{@gateway.url}/rest/pagamento?callback=&#{build_query(parameters)}")
          @response = JSON.parse(@response_raw[1..-2])

          self
        end

        def build_query(json)
          Rack::Utils.build_query({pagamentoWidget: json})
        end

        def build_json(creditcard)
          {
            pagamentoWidget: {
              referer: "http://www.celsodantas.com/", #TODO change this to merchant site url
              token: @token,
              dadosPagamento: {
                  Forma: "CartaoCredito",
                  Instituicao: "Visa",#creditcard.brand,
                  Parcelas: "1",
                  Recebimento: "AVista",
                  CartaoCredito: {
                      Numero: creditcard.number,
                      Expiracao: "#{creditcard.month}/#{creditcard.year}",
                      CodigoSeguranca: creditcard.verification_value,
                      Portador: {
                          Nome: creditcard.name,
                          DataNascimento: "01/09/2012",
                          Telefone: "7133515555",
                          Identidade: "222.222.222-22"
                      }
                  }
              }
            }
          }.to_json
        end

        def headers
          {
            :"Content-Type" => "application/json",
            :"Accept" => "application/json"
          }
        end

        def status
          @response["Status"]
        end

        def success?
          @response["StatusPagamento"] == "Sucesso"
        end

        def message
          @response["Mensagem"]
        end

      end
    end
  end
end