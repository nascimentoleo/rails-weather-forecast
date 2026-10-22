class ForecastsController < ApplicationController
  include ErrorHandling

  def new
  end

  def show
    address_input = validated_address_input
    forecast_input = validated_forecast_input

    @address_output = Address::Fetcher.call(address_input)
    @forecast_output = Forecast::CachedFetcher.call(address_output: @address_output, forecast_input: forecast_input)

    respond_to do |format|
      format.html
      format.json { render "api/v1/forecasts/show" }
    end
  end

  private

  def forecast_params
    params.permit(:units, :days).compact_blank
  end

  def validated_address_input
    Address::Input.new(full_address: params.expect(:full_address)).tap(&:validate!)
  end

  def validated_forecast_input
    Forecast::Input.new(forecast_params).tap(&:validate!)
  end

  def render_error(message, status)
    respond_to do |format|
      format.html do
        @error = message
        render :show, status: status
      end
      format.json { render json: { error: message }, status: status }
    end
  end
end
