require "swagger_helper"

RSpec.describe "Sesión", type: :request do
  path "/login" do
    post "Iniciar sesión" do
      tags "Sesión"
      description "Devuelve el token del cliente. Cada login genera un token nuevo e invalida el anterior. " \
                  "Límite: 10 intentos cada 3 minutos."
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, schema: { "$ref" => "#/components/schemas/login_request" }

      response "201", "Sesión iniciada" do
        let(:credentials) { { email_address: "portal@acme.com.ar", password: "password" } }
        schema "$ref" => "#/components/schemas/session"

        run_test! do |response|
          body = response.parsed_body
          expect(body["token"]).to eq(users(:acme_portal).reload.api_token)
          expect(body.dig("client", "business_name")).to eq(clients(:acme).business_name)
        end
      end

      response "401", "Credenciales incorrectas o usuario sin acceso al portal" do
        let(:credentials) { { email_address: "portal@acme.com.ar", password: "incorrecta" } }
        schema "$ref" => "#/components/schemas/error"
        run_test!
      end
    end
  end

  path "/logout" do
    delete "Cerrar sesión" do
      tags "Sesión"
      description "Invalida el token actual."
      requires_token

      response "204", "Sesión cerrada" do
        let(:Authorization) { "Bearer acme-token" }

        run_test! do
          expect(users(:acme_portal).reload.api_token).not_to eq("acme-token")
        end
      end
    end
  end
end
