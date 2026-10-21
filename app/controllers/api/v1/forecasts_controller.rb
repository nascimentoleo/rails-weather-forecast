module Api
  module V1
    class ForecastsController < BaseController
      rescue_from Address::Fetcher::NotFoundError do |error|
        render_error(error.message, :unprocessable_content)
      end

      rescue_from Address::Fetcher::ServiceError, Forecast::Fetcher::ServiceError do |error|
        render_error(error.message, :bad_gateway)
      end

      def show
        address_input = validated_address_input
        forecast_input = validated_forecast_input

        @address_output = Address::Fetcher.call(address_input)
        @forecast_output = Forecast::Fetcher.call(address: @address_output, forecast_input: forecast_input)
      end

      private

      def forecast_params
        params.permit(:units, :days).compact_blank
      end

      def validated_address_input
        Address::Input.new(full_address: params.expect(:address)).tap(&:validate!)
      end

      def validated_forecast_input
        Forecast::Input.new(forecast_params).tap(&:validate!)
      end
    end
  end
end
