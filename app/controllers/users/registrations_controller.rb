# frozen_string_literal: true

require "net/http"
require "json"

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :verify_turnstile, only: [ :create ]

  private

  def verify_turnstile
    return if turnstile_verified?

    self.resource = resource_class.new sign_up_params
    flash.now[:alert] = "Please complete the security check."
    render :new, status: :unprocessable_entity
  end

  def turnstile_verified?
    token = params["cf-turnstile-response"].presence
    secret = Rails.application.credentials.dig(:cloudflare, :turnstile_secret_key)

    # Skip verification in environments where the key is not configured (e.g. test)
    return true if secret.blank?
    return false if token.blank?

    uri = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(uri, {
      "secret"   => secret,
      "response" => token,
      "remoteip" => request.remote_ip
    })

    JSON.parse(response.body)["success"] == true
  rescue StandardError => e
    Rails.logger.error("Turnstile verification error: #{e.message}")
    false
  end
end
