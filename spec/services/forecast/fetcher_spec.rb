require "rails_helper"

RSpec.describe Forecast::Fetcher do
  subject(:fetch_forecast) { described_class.call(address: address_output, forecast_input: forecast_input) }

  let(:address_output) { build(:address_output) }
  let(:forecast_input) { build(:forecast_input, units: "fahrenheit", days: 2) }
  let(:open_meteo_client) { instance_double(OpenMeteo::Client) }
  let(:open_meteo_response) do
    {
      "current" => { "temperature_2m" => 61.2 },
      "daily" => {
        "time" => [ "2026-10-21", "2026-10-22" ],
        "temperature_2m_max" => [ 66.4, 68.0 ],
        "temperature_2m_min" => [ 50.1, 52.3 ]
      }
    }
  end

  before do
    allow(OpenMeteo::Client).to receive(:new).and_return(open_meteo_client)
    allow(open_meteo_client).to receive(:forecast).and_return(open_meteo_response)
  end

  describe ".call" do
    context "when Open-Meteo returns a forecast" do
      it "returns the current temperature and one temperature entry per day in the requested units" do
        expect(fetch_forecast).to have_attributes(
          units: "fahrenheit",
          current_temperature: 61.2,
          daily_temperatures: [
            { date: "2026-10-21", high: 66.4, low: 50.1 },
            { date: "2026-10-22", high: 68.0, low: 52.3 }
          ]
        )
      end

      it "requests the forecast for the address coordinates with the requested units and days" do
        fetch_forecast

        expect(open_meteo_client).to have_received(:forecast).with(latitude: address_output.latitude, longitude: address_output.longitude, temperature_unit: forecast_input.units, forecast_days: forecast_input.days)
      end
    end

    context "when the Open-Meteo response is missing fields" do
      let(:open_meteo_response) { { "current" => { "temperature_2m" => 61.2 } } }

      it "raises a service error explaining the failure" do
        expect { fetch_forecast }.to raise_error(described_class::ServiceError, "Could not reach the weather service")
      end
    end
  end
end
