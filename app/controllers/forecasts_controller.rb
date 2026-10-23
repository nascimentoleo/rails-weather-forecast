class ForecastsController < ApplicationController
  include ErrorHandling

  def new
  end

  def show
    address_input = validated_address_input
    forecast_input = validated_forecast_input

    @address_output = Address::CachedFetcher.call(address_input).first
    return render_error("Could not find a zip code for this address", :unprocessable_content) unless @address_output

    @forecast_output = Forecast::CachedFetcher.call(address_output: @address_output, forecast_input: forecast_input)

    respond_to do |format|
      format.html
      format.json { render "api/v1/forecasts/show" }
    end
  end

  private

  def permitted_params
    params.permit(:full_address, :units, :days)
  end

  def validated_address_input
    Address::Input.new(full_address: params.expect(:full_address)).tap(&:validate!)
  end

  def validated_forecast_input
    Forecast::Input.new(permitted_params.except(:full_address).compact_blank).tap(&:validate!)
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
