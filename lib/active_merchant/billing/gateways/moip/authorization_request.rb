module  ActiveMerchant #:nodoc:
  module Billing #:nodoc
    module MoipCore #:nodoc

      class AuthorizationRequest
        attr_reader :response
        
        def initialize(gateway, money, options)
          @gateway = gateway
          @money   = money
          @options = options
        end

        def request
          parameters = build_xml(@money, @options)
          @response_raw = @gateway.ssl_post("#{@gateway.url}/ws/alpha/EnviarInstrucao/Unica/", parameters, headers)
          @response = Hash.from_xml(@response_raw)
          self
        end

        def token
          @response["EnviarInstrucaoUnicaResponse"]["Resposta"]["Token"]
        end

        def success?
          @response["EnviarInstrucaoUnicaResponse"]["Resposta"]["Status"] == "Sucesso"
        end

        def error_message
          @response["EnviarInstrucaoUnicaResponse"]["Resposta"]["Erro"]
        end

        def id
          @response["EnviarInstrucaoUnicaResponse"]["Resposta"]["ID"]
        end

        def headers
          { 'authorization' => @gateway.basic_auth,
            'Content-Type'  => 'application/xml' }
        end

        # refactor it to external builder class
        def build_xml(money, options)
          xml  = ""
          address = options[:billing_address]

          root = Builder::XmlMarkup.new(target: xml)

          root.EnviarInstrucao do |n1| 
            n1.InstrucaoUnica(TipoValidacao: "Transparente") do |n2|
              n2.Razao(options[:reason])
              n2.Valores do |n3|
                n3.Valor("%.2f" % money, moeda: "BRL") 
              end

              n2.IdProprio(options[:order_id])

              n2.Recebedor do |n|
                n.LoginMoIP(options[:merchant_email])
              end

              n2.Pagador do |n4|
                n4.Nome(address[:name])
                n4.Email(address[:email])
                n4.IdPagador(address[:name] || address[:client_id])
                n4.EnderecoCobranca do |n5|
                  n5.Logradouro(address[:address1])
                  n5.Estado(address[:state])
                  n5.Pais(address[:country])
                  n5.Numero(address[:number])
                  n5.Bairro(address[:neighborhood])
                  n5.Cidade(address[:city])
                  n5.CEP(address[:zip])
                  n5.TelefoneFixo(address[:phone])
                end
              end
            end
          end
        end
      end

    end
  end
end
