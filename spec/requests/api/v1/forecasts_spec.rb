require "swagger_helper"

RSpec.describe "Forecasts API v1", type: :request do
  let(:address_input) { build(:address_input) }
  let(:address_output) { build(:address_output) }
  let(:from_cache) { false }
  let(:forecast_output) { build(:forecast_output, from_cache: from_cache) }

  before do
    allow(Address::CachedFetcher).to receive(:call).and_return([ address_output ])
    allow(Forecast::CachedFetcher).to receive(:call).and_return(forecast_output)
  end

  path "/api/v1/forecast" do
    get "Returns the current temperature and the daily forecast for the zip code of a US address" do
      tags "Forecast"
      produces "application/json"
      parameter name: :full_address, in: :query, required: true,
                description: "US address to look up", example: "1180 Seven Seas Dr", schema: { type: :string }
      parameter name: :units, in: :query, required: false,
                schema: { type: :string, enum: Forecast::Input::UNITS, default: Forecast::Input::DEFAULT_UNITS }
      parameter name: :days, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: Forecast::Input::MAX_DAYS, default: Forecast::Input::DEFAULT_DAYS }

      response "200", "the address and its forecast" do
        schema "$ref" => "#/components/schemas/forecast"

        let(:full_address) { address_input.full_address }

        context "when the address, units and days are valid" do
          let(:units) { "fahrenheit" }
          let(:days) { 2 }

          run_test! "returns the address and its forecast in the requested units and days" do
            expect(Address::CachedFetcher).to have_received(:call).with(having_attributes(full_address: address_input.full_address))
            expect(Forecast::CachedFetcher).to have_received(:call).with(
              address_output: address_output,
              forecast_input: having_attributes(units: "fahrenheit", days: 2)
            )
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
        end

        context "when the forecast comes from the cache" do
          let(:from_cache) { true }

          run_test! "indicates that the result was pulled from the cache" do
            expect(response.parsed_body).to include("from_cache" => true)
          end
        end

        context "when the units and days are not given" do
          run_test! "fetches the forecast with the default units and days" do
            expect(Forecast::CachedFetcher).to have_received(:call).with(
              address_output: address_output,
              forecast_input: having_attributes(units: Forecast::Input::DEFAULT_UNITS, days: Forecast::Input::DEFAULT_DAYS)
            )
          end
        end
      end

      response "400", "invalid parameters" do
        schema "$ref" => "#/components/schemas/error"

        context "when the address is missing" do
          let(:full_address) { nil }
          let(:units) { "fahrenheit" }
          let(:days) { 2 }

          run_test! "responds with bad request without looking up the address" do
            expect(response.parsed_body).to eq("error" => "Full address is required")
            expect(Address::CachedFetcher).not_to have_received(:call)
          end
        end

        context "when the units are invalid" do
          let(:full_address) { address_input.full_address }
          let(:units) { "kelvin" }

          run_test! "responds with bad request without looking up the address" do
            expect(response.parsed_body).to eq("error" => "Units must be one of: fahrenheit, celsius")
            expect(Address::CachedFetcher).not_to have_received(:call)
          end
        end
      end

      response "422", "no address with a zip code was found" do
        schema "$ref" => "#/components/schemas/error"

        let(:full_address) { address_input.full_address }

        before { allow(Address::CachedFetcher).to receive(:call).and_return([]) }

        run_test! "explains that the address could not be found without fetching a forecast" do
          expect(response.parsed_body).to eq("error" => "Could not find a zip code for this address")
          expect(Forecast::CachedFetcher).not_to have_received(:call)
        end
      end

      response "502", "address lookup or weather service failed" do
        schema "$ref" => "#/components/schemas/error"

        let(:full_address) { address_input.full_address }

        before { allow(Forecast::CachedFetcher).to receive(:call).and_raise(Forecast::Fetcher::ServiceError, "Weather service timed out, please try again") }

        run_test! "explains the failure" do
          expect(response.parsed_body).to eq("error" => "Weather service timed out, please try again")
        end
      end
    end
  end
end
