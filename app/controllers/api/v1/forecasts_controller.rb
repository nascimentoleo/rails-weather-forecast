module Api
  module V1
    class ForecastsController < BaseController
      rescue_from Address::Resolver::NotFoundError do |error|
        render_error(error.message, :unprocessable_content)
      end

      rescue_from Address::Resolver::ServiceError do |error|
        render_error(error.message, :bad_gateway)
      end

      def show
        address = Address.new(full_address: params.expect(:address))
        address.validate!
        Address::Resolver.call(address)

        head :no_content
      end
    end
  end
end
