# Shortcuts shared by the rswag specs in spec/requests/api/v1.
module ApiDocsHelper
  # Declares the Bearer header and the 401 response of a protected operation.
  def requires_token
    security [ bearer: [] ]
    parameter name: :Authorization, in: :header, type: :string, required: true,
      description: "Bearer <token>"

    response "401", "Token inválido o ausente" do
      let(:Authorization) { "Bearer token-inexistente" }
      schema "$ref" => "#/components/schemas/error"
      run_test!
    end
  end

  # Documents an error response that uses the common error shape.
  def error_response(status, description, &block)
    response status.to_s, description do
      schema "$ref" => "#/components/schemas/error"
      instance_exec(&block) if block
      run_test!
    end
  end
end

RSpec.configure do |config|
  config.extend ApiDocsHelper, type: :request
end
