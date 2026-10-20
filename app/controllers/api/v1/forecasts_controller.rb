module Api
  module V1
    class ForecastsController < ActionController::API
      rescue_from ActionController::ParameterMissing do
        render_bad_request("Address is required")
      end

      rescue_from AddressValidator::InvalidAddressError do |error|
        render_bad_request(error.message)
      end

      def show
        AddressValidator.call(params.expect(:address))

        head :no_content
      end

      private

      def render_bad_request(message)
        render json: { error: message }, status: :bad_request
      end
    end
  end
end
