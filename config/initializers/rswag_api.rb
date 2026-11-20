# Serves the files in swagger/ (generated with `bin/rails rswag:specs:swaggerize`)
# at /api-docs/<path>, e.g. /api-docs/v1/openapi.yaml.
Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.join("swagger").to_s
end
