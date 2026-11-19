require "test_helper"
require_relative "api_test_helper"

class Api::V1::CorsTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  FRONTEND = "https://frontend.example.com".freeze

  def preflight(path, origin: FRONTEND, method: "GET", headers: "Authorization, Content-Type")
    process :options, path, headers: {
      "Origin" => origin,
      "Access-Control-Request-Method" => method,
      "Access-Control-Request-Headers" => headers
    }
  end

  test "the preflight from the frontend is answered without a token" do
    preflight api_v1_projects_path

    assert_response :success
    assert_equal FRONTEND, response.headers["access-control-allow-origin"]
    assert_equal "GET, POST, DELETE, OPTIONS", response.headers["access-control-allow-methods"]
    assert_equal "authorization, content-type", response.headers["access-control-allow-headers"].downcase
  end

  test "the preflight for the login works too" do
    preflight api_v1_login_path, method: "POST", headers: "Content-Type"

    assert_response :success
    assert_equal FRONTEND, response.headers["access-control-allow-origin"]
  end

  test "an API request from the frontend gets the CORS header" do
    get api_v1_projects_path, headers: auth_headers(users(:acme_portal)).merge("Origin" => FRONTEND)

    assert_response :success
    assert_equal FRONTEND, response.headers["access-control-allow-origin"]
  end

  test "another origin is not allowed" do
    preflight api_v1_projects_path, origin: "https://otro-sitio.example.com"

    assert_nil response.headers["access-control-allow-origin"]
  end

  test "a method outside the list is not allowed" do
    preflight api_v1_budget_path(budgets(:acme_sent)), method: "PATCH"

    assert_nil response.headers["access-control-allow-origin"]
  end

  test "a header outside the list is not allowed" do
    preflight api_v1_projects_path, headers: "X-Custom"

    assert_nil response.headers["access-control-allow-origin"]
  end

  test "the back-office is not exposed to CORS" do
    get new_session_path, headers: { "Origin" => FRONTEND }

    assert_nil response.headers["access-control-allow-origin"]
  end
end
