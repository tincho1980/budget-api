require "swagger_helper"

RSpec.describe "Pagos", type: :request do
  let(:Authorization) { "Bearer acme-token" }

  payment_body = { type: :object, required: %w[ payment ], additionalProperties: false,
                   properties: { payment: { "$ref" => "#/components/schemas/payment" } } }

  path "/payments" do
    get "Listar los pagos informados" do
      tags "Pagos"
      produces "application/json"
      requires_token

      response "200", "Pagos del cliente, del más reciente al más viejo" do
        schema type: :object, required: %w[ payments ], additionalProperties: false,
          properties: { payments: { type: :array, items: { "$ref" => "#/components/schemas/payment" } } }
        run_test!
      end
    end

    post "Informar un pago" do
      tags "Pagos"
      description <<~MD
        El pago queda en `pending_review` y no se aplica a ninguna cuota hasta que un
        administrador lo confirma en el back-office.

        Se puede enviar como JSON (sin comprobante) o como `multipart/form-data` con el
        comprobante en `receipt`: PDF, JPG o PNG de hasta 5 MB.
      MD
      consumes "application/json", "multipart/form-data"
      produces "application/json"
      requires_token
      # JSON body...
      parameter name: :payment, in: :body, schema: { "$ref" => "#/components/schemas/payment_request" }
      # ...or the same fields as multipart/form-data, plus the receipt.
      parameter name: :amount, in: :formData, schema: { type: :string }, required: true
      parameter name: :paid_on, in: :formData, schema: { type: :string, format: :date }, required: true
      parameter name: :payment_method, in: :formData, schema: { type: :string, enum: Payment.payment_methods.keys }, required: true
      parameter name: :notes, in: :formData, schema: { type: :string }
      parameter name: :receipt, in: :formData, schema: { type: :string, format: :binary },
        description: "Comprobante: PDF, JPG o PNG de hasta 5 MB"

      let(:payment) { { amount: "100000", paid_on: Date.current.iso8601, payment_method: "transfer" } }

      response "201", "Pago informado" do
        schema payment_body

        run_test! do |response|
          expect(response.parsed_body.dig("payment", "status")).to eq("pending_review")
          expect(response.parsed_body.dig("payment", "receipt")).to be_nil
        end

        context "con comprobante (multipart)" do
          let(:"Content-Type") { "multipart/form-data" }
          let(:amount) { "100000" }
          let(:paid_on) { Date.current.iso8601 }
          let(:payment_method) { "transfer" }
          let(:notes) { "Transferencia de septiembre" }
          let(:receipt) { Rack::Test::UploadedFile.new(file_fixture("comprobante.pdf"), "application/pdf") }

          run_test! do |response|
            expect(response.parsed_body.dig("payment", "receipt", "filename")).to eq("comprobante.pdf")
            expect(Payment.last.receipt).to be_attached
          end
        end
      end

      error_response 422, "Datos inválidos o comprobante no permitido" do
        let(:payment) { { amount: "-1", paid_on: Date.current.iso8601, payment_method: "transfer" } }
      end
    end
  end
end
