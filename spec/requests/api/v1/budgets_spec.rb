require "swagger_helper"

RSpec.describe "Presupuestos", type: :request do
  let(:Authorization) { "Bearer acme-token" }
  let(:id) { budgets(:acme_sent).id }

  budget_body = { type: :object, required: %w[ budget ], additionalProperties: false,
                  properties: { budget: { "$ref" => "#/components/schemas/budget" } } }

  path "/budgets/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Ver un presupuesto" do
      tags "Presupuestos"
      description "Los borradores no son visibles para el cliente y responden 404."
      produces "application/json"
      requires_token

      response "200", "Presupuesto agrupado por módulo" do
        schema budget_body
        run_test!
      end

      error_response 404, "Borrador, inexistente o de otro cliente" do
        let(:id) { budgets(:acme_draft).id }
      end
    end
  end

  path "/budgets/{id}/approve" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Aprobar un presupuesto" do
      tags "Presupuestos"
      description "Solo se puede decidir sobre un presupuesto enviado (status sent). Avisa por mail a los administradores."
      produces "application/json"
      requires_token

      response "200", "Presupuesto aprobado" do
        schema budget_body

        run_test! do |response|
          expect(response.parsed_body.dig("budget", "status")).to eq("approved")
          expect(response.parsed_body.dig("budget", "approved_at")).to be_present
        end
      end

      error_response 422, "El presupuesto ya fue decidido" do
        let(:id) { budgets(:closed_approved).id }
      end

      error_response 404, "Borrador, inexistente o de otro cliente" do
        let(:id) { budgets(:globex_sent).id }
      end
    end
  end

  path "/budgets/{id}/reject" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Rechazar un presupuesto" do
      tags "Presupuestos"
      description "Solo se puede decidir sobre un presupuesto enviado (status sent). Avisa por mail a los administradores."
      produces "application/json"
      requires_token

      response "200", "Presupuesto rechazado" do
        schema budget_body

        run_test! do |response|
          expect(response.parsed_body.dig("budget", "status")).to eq("rejected")
        end
      end

      error_response 422, "El presupuesto ya fue decidido" do
        let(:id) { budgets(:closed_approved).id }
      end
    end
  end
end
