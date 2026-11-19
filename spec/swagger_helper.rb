# Base of the OpenAPI document. The paths come from the specs in spec/requests;
# `bin/rails rswag:specs:swaggerize` runs them and writes swagger/v1/openapi.yaml.
require "rails_helper"
require_relative "support/api_docs_helper"

# Amounts and hours travel as strings with two decimals ("380000.00") so the
# client never loses precision with floating point.
DECIMAL = { type: :string, pattern: '^-?\d+\.\d{2}$', example: "380000.00" }.freeze

# Shared by GET /projects (list) and GET /projects/{id} (adds the budgets).
PROJECT = {
  type: :object,
  required: %w[ id name description status started_on closed_on current_budget ],
  additionalProperties: false,
  properties: {
    id: { type: :integer },
    name: { type: :string, example: "Sitio web Acme" },
    description: { type: :string, nullable: true },
    status: { type: :string, enum: Project.statuses.keys },
    started_on: { type: :string, format: :date, nullable: true },
    closed_on: { type: :string, format: :date, nullable: true },
    current_budget: {
      description: "Última versión enviada al cliente (los borradores no se muestran)",
      type: :object,
      nullable: true,
      required: %w[ id version status total pending_approval ],
      additionalProperties: false,
      properties: {
        id: { type: :integer },
        version: { type: :integer },
        status: { type: :string, enum: Budget.statuses.keys },
        total: DECIMAL,
        pending_approval: { type: :boolean, description: "true si espera la decisión del cliente" }
      }
    }
  }
}.freeze

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.openapi_format = :yaml

  config.openapi_specs = {
    "v1/openapi.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "adavra-sales — API del portal de clientes",
        version: "v1",
        description: <<~MD
          API que usa el portal de clientes. Cada cliente ve solo sus propios proyectos,
          presupuestos, cuotas y pagos: un recurso de otro cliente responde **404**.

          **Autenticación:** `POST /login` devuelve un token. Se envía en cada pedido como
          `Authorization: Bearer <token>`. `DELETE /logout` lo invalida. Solo los usuarios
          con rol cliente tienen acceso.

          **Errores:** siempre con la forma `{ "error": { "status", "message", "details" } }`.

          **Montos y horas:** strings con dos decimales (`"380000.00"`).
        MD
      },
      servers: [
        { url: "https://adavra-sales.onrender.com/api/v1", description: "Producción (Render)" },
        { url: "http://localhost:3000/api/v1", description: "Desarrollo" }
      ],
      tags: [
        { name: "Sesión", description: "Login y logout del portal" },
        { name: "Proyectos" },
        { name: "Presupuestos", description: "Consulta, aprobación y rechazo" },
        { name: "Cuenta", description: "Deuda y cuotas de mantenimiento" },
        { name: "Pagos", description: "Pagos informados por el cliente" }
      ],
      paths: {},
      components: {
        securitySchemes: {
          bearer: { type: :http, scheme: :bearer, description: "Token obtenido con POST /login" }
        },
        schemas: {
          error: {
            type: :object,
            required: %w[ error ],
            additionalProperties: false,
            properties: {
              error: {
                type: :object,
                required: %w[ status message ],
                additionalProperties: false,
                properties: {
                  status: { type: :integer, example: 404 },
                  message: { type: :string, example: "Recurso no encontrado." },
                  details: { type: :array, items: { type: :string }, example: [ "Monto debe ser mayor que 0" ] }
                }
              }
            }
          },
          login_request: {
            type: :object,
            required: %w[ email_address password ],
            properties: {
              email_address: { type: :string, format: :email, example: "portal@acme.com.ar" },
              password: { type: :string, format: :password, example: "password" }
            }
          },
          session: {
            type: :object,
            required: %w[ token token_type user client ],
            additionalProperties: false,
            properties: {
              token: { type: :string, example: "Xk2fP9qL7wR4tY1uZ8vB3nM6" },
              token_type: { type: :string, enum: %w[ Bearer ] },
              user: {
                type: :object,
                required: %w[ id name email_address ],
                additionalProperties: false,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  email_address: { type: :string, format: :email }
                }
              },
              client: {
                type: :object,
                required: %w[ id business_name ],
                additionalProperties: false,
                properties: { id: { type: :integer }, business_name: { type: :string } }
              }
            }
          },
          project: PROJECT,
          project_detail: PROJECT.merge(
            required: PROJECT[:required] + %w[ budgets ],
            properties: PROJECT[:properties].merge(
              budgets: {
                type: :array,
                items: {
                  type: :object,
                  required: %w[ id version status total ],
                  additionalProperties: false,
                  properties: {
                    id: { type: :integer },
                    version: { type: :integer },
                    status: { type: :string, enum: Budget.statuses.keys },
                    total: DECIMAL
                  }
                }
              }
            )
          ),
          budget: {
            type: :object,
            description: "Solo lo facturable: sin tarifas, costos internos ni horas cargadas por el equipo",
            required: %w[ id version status sent_at approved_at notes total signed_document_url project estimated_hours modules ],
            additionalProperties: false,
            properties: {
              id: { type: :integer },
              version: { type: :integer },
              status: { type: :string, enum: Budget.statuses.keys },
              sent_at: { type: :string, format: "date-time", nullable: true },
              approved_at: { type: :string, format: "date-time", nullable: true },
              notes: { type: :string, nullable: true },
              total: DECIMAL,
              signed_document_url: { type: :string, format: :uri, nullable: true },
              project: {
                type: :object,
                required: %w[ id name ],
                additionalProperties: false,
                properties: { id: { type: :integer }, name: { type: :string } }
              },
              estimated_hours: DECIMAL.merge(example: "40.00"),
              modules: {
                type: :array,
                items: {
                  type: :object,
                  required: %w[ name items ],
                  additionalProperties: false,
                  properties: {
                    name: { type: :string, example: "General" },
                    items: {
                      type: :array,
                      items: {
                        type: :object,
                        required: %w[ description estimated_hours ],
                        additionalProperties: false,
                        properties: {
                          description: { type: :string },
                          estimated_hours: DECIMAL.merge(example: "8.00")
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          charge: {
            type: :object,
            description: "Cuota mensual de mantenimiento",
            required: %w[ id period due_on status amount paid_amount balance days_overdue ],
            additionalProperties: false,
            properties: {
              id: { type: :integer },
              period: { type: :string, pattern: '^\d{4}-\d{2}$', example: "2026-08" },
              due_on: { type: :string, format: :date },
              status: { type: :string, enum: MaintenanceCharge.statuses.keys },
              amount: DECIMAL,
              paid_amount: DECIMAL,
              balance: DECIMAL,
              days_overdue: { type: :integer, minimum: 0 }
            }
          },
          payment: {
            type: :object,
            required: %w[ id paid_on payment_method status notes created_at amount receipt ],
            additionalProperties: false,
            properties: {
              id: { type: :integer },
              paid_on: { type: :string, format: :date },
              payment_method: { type: :string, enum: Payment.payment_methods.keys },
              status: { type: :string, enum: Payment.statuses.keys, description: "Un pago informado queda en pending_review hasta que un admin lo confirma" },
              notes: { type: :string, nullable: true },
              created_at: { type: :string, format: "date-time" },
              amount: DECIMAL,
              receipt: {
                type: :object,
                nullable: true,
                required: %w[ filename content_type byte_size url ],
                additionalProperties: false,
                properties: {
                  filename: { type: :string, example: "comprobante.pdf" },
                  content_type: { type: :string, enum: %w[ application/pdf image/jpeg image/png ] },
                  byte_size: { type: :integer },
                  url: { type: :string, format: :uri }
                }
              }
            }
          },
          account: {
            type: :object,
            required: %w[ client debt overdue_charges unpaid_charges recent_payments ],
            additionalProperties: false,
            properties: {
              client: {
                type: :object,
                required: %w[ id business_name tax_id ],
                additionalProperties: false,
                properties: { id: { type: :integer }, business_name: { type: :string }, tax_id: { type: :string, nullable: true } }
              },
              debt: DECIMAL.merge(description: "Saldo pendiente de las cuotas impagas"),
              overdue_charges: { type: :integer, description: "Cantidad de cuotas vencidas" },
              unpaid_charges: { type: :array, items: { "$ref" => "#/components/schemas/charge" } },
              recent_payments: { type: :array, maxItems: 5, items: { "$ref" => "#/components/schemas/payment" } }
            }
          },
          payment_request: {
            type: :object,
            required: %w[ amount paid_on payment_method ],
            properties: {
              amount: { type: :string, example: "100000" },
              paid_on: { type: :string, format: :date, example: "2026-09-10" },
              payment_method: { type: :string, enum: Payment.payment_methods.keys },
              notes: { type: :string },
              receipt: { type: :string, format: :binary, description: "Solo en multipart/form-data: PDF, JPG o PNG de hasta 5 MB" }
            }
          }
        }
      }
    }
  }
end
