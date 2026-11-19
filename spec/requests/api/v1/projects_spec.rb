require "swagger_helper"

RSpec.describe "Proyectos", type: :request do
  let(:Authorization) { "Bearer acme-token" }

  path "/projects" do
    get "Listar los proyectos del cliente" do
      tags "Proyectos"
      produces "application/json"
      requires_token

      response "200", "Proyectos ordenados por nombre" do
        schema type: :object, required: %w[ projects ], additionalProperties: false,
          properties: { projects: { type: :array, items: { "$ref" => "#/components/schemas/project" } } }

        run_test! do |response|
          names = response.parsed_body["projects"].pluck("name")
          expect(names).to match_array(clients(:acme).projects.pluck(:name))
        end
      end
    end
  end

  path "/projects/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Ver un proyecto con sus presupuestos" do
      tags "Proyectos"
      produces "application/json"
      requires_token
      let(:id) { projects(:acme_web).id }

      response "200", "Proyecto con los presupuestos enviados al cliente" do
        schema type: :object, required: %w[ project ], additionalProperties: false,
          properties: { project: { "$ref" => "#/components/schemas/project_detail" } }

        run_test! do |response|
          statuses = response.parsed_body.dig("project", "budgets").pluck("status")
          expect(statuses).not_to include("draft")
        end
      end

      error_response 404, "No existe o es de otro cliente" do
        let(:id) { projects(:globex_app).id }
      end
    end
  end
end
