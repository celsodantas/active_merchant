# THIS IS A WORKING CODE:
# USE THIS AS A REFERENCE
# IT HAS NOT BEEN TESTED IN PRODUCTION, ONLY IN SANDBOX MODE

# require 'builder'
# require 'httparty'
# require 'debugger'
# require "rexml/document"
# require 'json'

# xml  = ""
# root = Builder::XmlMarkup.new(target: xml)

# def payment_receiver_login
#   "celsodantas@gmail.com"
# end

# def payment_receiver_name
#   "bob nelson"
# end


# def payment_receiver_to_xml(node)
#   node.Recebedor do |n|
#     n.LoginMoIP(payment_receiver_login)
#     # n.Apelido(payment_receiver_name)
#   end
# end

# root.EnviarInstrucao do |n1|
#   n1.InstrucaoUnica(TipoValidacao: "Transparente") do |n2|
#     n2.Razao("Cha de cozinha")
#     n2.Valores do |n3|
#       [55.99].each { |v| n3.Valor("%.2f" % v, moeda: "BRL") }
#     end
#     n2.IdProprio("compra_2013_3")

#     payment_receiver_to_xml n2 if payment_receiver_login
#     n2.Pagador do |n4|
#       n4.Nome("Joao")
#       n4.Email("joao@email.com")
#       n4.IdPagador("joao_1234")
#       n4.EnderecoCobranca do |n5|
#         n5.Logradouro("Rua da Maciota")
#         n5.Estado("SP")
#         n5.Pais("BRA")
#         n5.Numero("166")
#         n5.Bairro("Pituba")
#         n5.Cidade("Sao Paulo")
#         n5.CEP("41810-825")
#         n5.TelefoneFixo("(11)8888-8888")
#       end
#     end
#     # <Pagador>
#     #            <Nome>Nome Sobrenome</Nome>
#     #            <Email>email@cliente.com.br</Email>
#     #            <IdPagador>id_usuario</IdPagador>
#     #            <EnderecoCobranca>
#     #                <Logradouro>Rua do Zézinho Coração</Logradouro>
#     #                <Numero>45</Numero>
#     #                <Complemento>z</Complemento>
#     #                <Bairro>Palhaço Jão</Bairro>
#     #                <Cidade>São Paulo</Cidade>
#     #                <Estado>SP</Estado>
#     #                <Pais>BRA</Pais>
#     #                <CEP>01230-000</CEP>
#     #                <TelefoneFixo>(11)8888-8888</TelefoneFixo>
#     #            </EnderecoCobranca>
#     #        </Pagador>

#   end
# end


# puts "------------"
# REXML::Document.new(xml).write($stdout, 2)
# puts "\n------------"

# ####################

# url = "https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica/"

# params = {
#   http_method: "post",
#   body:        xml,
# }

# login = "3BTLZDXCU2FXPPQV9QAY7FAZQMUISIYD"
# password = "DRG0UHVE4N2TER26LBNGUBVZSDNOUZN9YFMPKTNQ"
# params[:basic_auth] = { username: login, password: password }

# @response = HTTParty.send params[:http_method], url, params

# puts JSON.pretty_generate @response


###
# JSON complete payment example
# {
#     "Forma": "CartaoCredito",
#     "Instituicao": "Visa",
#     "Parcelas": "1",
#     "Recebimento": "AVista",
#     "CartaoCredito": {
#         "Numero": "4073020000000002",
#         "Expiracao": "12/15",
#         "CodigoSeguranca": "123",
#         "Portador": {
#             "Nome": "Nome Sobrenome",
#             "DataNascimento": "30/12/1987",
#             "Telefone": "(11)3165-4020",
#             "Identidade": "222.222.222-22"
#         }
#     }
# }



module  ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class MoipGateway < Gateway

      class AuthorizationRequest
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

      class CompletePurchase
        def initialize(gateway, creditcard, token)
          @gateway    = gateway
          @creditcard = creditcard
          @token      = token
        end

        def request
          parameters = build_json(@creditcard)
          @response_raw = @gateway.ssl_get("#{@gateway.url}/rest/pagamento?callback=&#{encode(parameters)}")
          puts parameters
          puts ""
          puts encode(parameters)
          puts ""
          puts @response_raw
          puts ""
          puts "#{@gateway.url}/rest/pagamento?callback=?#{encode(parameters)}"
          self
        end

        def encode(hash)
          Rack::Utils.build_nested_query(hash)
          # CGI.unescape(hash.to_query)
        end

        def build_json(creditcard)
          # JSON.generate(
          {
            pagamentoWidget: {
              referer: "http://localhost", #TODO change this to merchant site url
              token: @token,
              dadosPagamento: {
                  Forma: "CartaoCredito",
                  Instituicao: creditcard.brand,
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
          }
          # )
        end

        def headers
          { 'Content-Type'  => 'application/x-www-form-urlencoded' }
        end

      end

      self.test_url = 'https://desenvolvedor.moip.com.br/sandbox'
      self.live_url = 'https://www.moip.com.br'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['BR']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.moip.com.br/'

      # The name of the gateway
      self.display_name = 'MOIP'

      def initialize(options = {})
        requires!(options, :email, :access_token, :secret)

        @merchant_email = options[:email]
        @access_token   = options[:access_token]
        @secret         = options[:secret]

        super
      end

      # Didn't find any info about authorization
      # def authorize(money, creditcard, options = {})
      #   post = {}
      #   add_invoice(post, options)
      #   add_creditcard(post, creditcard)
      #   add_address(post, creditcard, options)
      #   add_customer_data(post, options)

      #   commit('authonly', money, post)
      # end

      def purchase(money, creditcard, options = {})
        options.update({merchant_email: @merchant_email})
        authorization = AuthorizationRequest.new(self, money, options).request

        puts "ERROR!" unless authorization.success?

        complete      = CompletePurchase.new(self, creditcard, authorization.token).request
      end

      # there's no capture event
      # def capture(money, authorization, options = {})
      #   get_token('capture', money, post)
      # end

      def url
        test? ? test_url : live_url
      end

      def basic_auth
        'Basic ' + ["#{@options[:access_token]}:#{@options[:secret]}"].pack('m').delete("\r\n")
      end

      private

      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)
      end

      def add_invoice(post, options)
      end

      def add_creditcard(post, creditcard)
      end

      def parse(body)
      end

      def complete_purchase(token, creditcard)
        
      end

      def message_from(response)
      end

      def post_data(action, parameters = {})
      end
      
    end
  end
end