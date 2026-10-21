module Api
  module V1
    class ForecastsController < BaseController
      rescue_from Address::Resolver::NotFoundError do |error|
        render_error(error.message, :unprocessable_content)
      end

      rescue_from Address::Resolver::ServiceError, Forecast::Fetcher::ServiceError do |error|
        render_error(error.message, :bad_gateway)
      end

      def show
        address = Address.new(full_address: params.expect(:address))
        address.validate!

        forecast = Forecast.new(forecast_params)
        forecast.validate!

        address = Address::Resolver.call(address)
        forecast = Forecast::Fetcher.call(address: address, forecast: forecast)

        head :no_content
      end

      private

      def forecast_params
        params.permit(:units, :days).compact_blank
      end
    end
  end
end
