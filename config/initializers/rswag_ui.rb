# Swagger UI at /api-docs, reading the generated OpenAPI file.
Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api-docs/v1/openapi.yaml", "adavra-sales API v1"
end
