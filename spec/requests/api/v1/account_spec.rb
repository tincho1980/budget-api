require "swagger_helper"

RSpec.describe "Cuenta", type: :request do
  let(:Authorization) { "Bearer acme-token" }

  path "/account" do
    get "Ver el estado de cuenta" do
      tags "Cuenta"
      description "Deuda total, cuotas impagas (de la más vieja a la más nueva) y los últimos 5 pagos."
      produces "application/json"
      requires_token

      response "200", "Estado de cuenta del cliente" do
        schema type: :object, required: %w[ account ], additionalProperties: false,
          properties: { account: { "$ref" => "#/components/schemas/account" } }

        run_test! do |response|
          expect(response.parsed_body.dig("account", "debt")).to eq("200000.00")
        end
      end
    end
  end

  path "/charges" do
    get "Listar las cuotas de mantenimiento" do
      tags "Cuenta"
      description "De la más nueva a la más vieja. Se pueden filtrar por estado."
      produces "application/json"
      requires_token
      parameter name: :status, in: :query, required: false,
        schema: { type: :string, enum: MaintenanceCharge.statuses.keys }

      response "200", "Cuotas del cliente" do
        let(:status) { "overdue" }
        schema type: :object, required: %w[ charges ], additionalProperties: false,
          properties: { charges: { type: :array, items: { "$ref" => "#/components/schemas/charge" } } }

        run_test! do |response|
          expect(response.parsed_body["charges"].pluck("status").uniq).to eq(%w[ overdue ])
        end
      end

      error_response 400, "Estado inválido" do
        let(:status) { "cualquiera" }
      end
    end
  end
end
