# Lets the frontend at FRONTEND_ORIGIN (config.x.frontend_origin, set in
# config/application.rb) call the API from the browser.
#
# - Only /api/v1/*: the back-office is rendered by Rails itself and needs no CORS.
# - Rack::Cors goes first in the middleware stack, so the preflight (OPTIONS) is
#   answered there and never reaches Api::V1::BaseController: it needs no token.
# - No credentials: the API authenticates with the Authorization header, not cookies.
# - Without FRONTEND_ORIGIN no origin is allowed (never "*").
frontend_origin = Rails.configuration.x.frontend_origin

if frontend_origin
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins frontend_origin

      resource "/api/v1/*",
        methods: %i[ get post delete options ],
        headers: %w[ Authorization Content-Type ]
    end
  end
end
