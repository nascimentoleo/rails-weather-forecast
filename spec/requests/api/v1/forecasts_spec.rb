require "rails_helper"

RSpec.describe "Forecasts API v1", type: :request do
  subject(:get_forecast) { get api_v1_forecast_path, params: params }

  let(:address_input) { build(:address_input) }
  let(:address_output) { build(:address_output) }
  let(:params) { { full_address: address_input.full_address, units: "fahrenheit", days: 2 } }
  let(:from_cache) { false }
  let(:forecast_output) { build(:forecast_output, from_cache: from_cache) }

  before do
    allow(Address::Fetcher).to receive(:call).and_return(address_output)
    allow(Forecast::CachedFetcher).to receive(:call).and_return(forecast_output)
  end

  describe "GET /api/v1/forecast" do
    context "when the address, units and days are valid" do
      it "returns the address and its forecast as JSON" do
        get_forecast

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "from_cache" => false,
          "address" => {
            "full_address" => address_output.full_address,
            "zip" => address_output.zip,
            "latitude" => address_output.latitude,
            "longitude" => address_output.longitude
          },
          "forecast" => {
            "units" => forecast_output.units,
            "current_temperature" => forecast_output.current_temperature,
            "daily_temperatures" => forecast_output.daily_temperatures.as_json
          }
        )
      end

      it "fetches the forecast for the resolved address with the requested units and days" do
        get_forecast

        expect(Address::Fetcher).to have_received(:call).with(having_attributes(full_address: address_input.full_address))
        expect(Forecast::CachedFetcher).to have_received(:call).with(
          address_output: address_output,
          forecast_input: having_attributes(units: "fahrenheit", days: 2)
        )
      end

      context "and the forecast comes from the cache" do
        let(:from_cache) { true }

        it "indicates that the result was pulled from the cache" do
          get_forecast

          expect(response.parsed_body).to include("from_cache" => true)
        end
      end
    end

    context "when the units and days are not given" do
      let(:params) { { full_address: address_input.full_address } }

      it "fetches the forecast with the default units and days" do
        get_forecast

        expect(Forecast::CachedFetcher).to have_received(:call).with(
          address_output: address_output,
          forecast_input: having_attributes(units: Forecast::Input::DEFAULT_UNITS, days: Forecast::Input::DEFAULT_DAYS)
        )
      end
    end

    context "when the address is missing" do
      let(:params) { { units: "fahrenheit", days: 2 } }

      it "responds with bad request without looking up the address" do
        get_forecast

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "Full address is required")
        expect(Address::Fetcher).not_to have_received(:call)
      end
    end

    context "when the units are invalid" do
      let(:params) { { full_address: address_input.full_address, units: "kelvin" } }

      it "responds with bad request without looking up the address" do
        get_forecast

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "Units must be one of: fahrenheit, celsius")
        expect(Address::Fetcher).not_to have_received(:call)
      end
    end
  end
end
