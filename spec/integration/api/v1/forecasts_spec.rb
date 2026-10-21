require "rails_helper"

RSpec.describe "Forecasts API v1 integration", type: :request do
  subject(:get_forecast) { get api_v1_forecast_path, params: params }

  let(:address_input) { build(:address_input) }
  let(:params) { { address: address_input.full_address, units: "fahrenheit", days: 2 } }
  let(:original_cache) { Rails.cache }

  let(:nominatim_url) { "https://nominatim.openstreetmap.org/search" }
  let(:nominatim_request) do
    {
      "q" => address_input.full_address,
      "countrycodes" => "us",
      "format" => "json",
      "addressdetails" => "1",
      "accept-language" => "en"
    }
  end
  let(:nominatim_headers) { { "User-Agent" => Geocoder.config.http_headers.fetch("User-Agent") } }
  let(:nominatim_stub) { stub_request(:get, nominatim_url).with(query: nominatim_request, headers: nominatim_headers) }
  let(:nominatim_response) do
    <<~JSON
      [
        {
          "lat": "28.4177374",
          "lon": "-81.5811767",
          "address": { "postcode": "32830" }
        }
      ]
    JSON
  end

  let(:open_meteo_url) { "https://api.open-meteo.com/v1/forecast" }
  let(:open_meteo_request) do
    {
      latitude: "28.4177374",
      longitude: "-81.5811767",
      current: "temperature_2m",
      daily: "temperature_2m_max,temperature_2m_min",
      temperature_unit: "fahrenheit",
      forecast_days: "2",
      timezone: "auto"
    }
  end
  let(:open_meteo_stub) { stub_request(:get, open_meteo_url).with(query: open_meteo_request) }
  let(:open_meteo_response) do
    <<~JSON
      {
        "current": { "temperature_2m": 61.2 },
        "daily": {
          "time": ["2026-10-21", "2026-10-22"],
          "temperature_2m_max": [66.4, 68.0],
          "temperature_2m_min": [50.1, 52.3]
        }
      }
    JSON
  end

  before do
    original_cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  after { Rails.cache = original_cache }

  describe "GET /api/v1/forecast" do
    context "when Nominatim and Open-Meteo respond successfully" do
      before do
        nominatim_stub.to_return(status: 200, body: nominatim_response)
        open_meteo_stub.to_return(status: 200, body: open_meteo_response)
      end

      it "returns the address and its forecast as JSON" do
        get_forecast

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "from_cache" => false,
          "address" => {
            "full_address" => address_input.full_address,
            "zip" => "32830",
            "latitude" => 28.4177374,
            "longitude" => -81.5811767
          },
          "forecast" => {
            "units" => "fahrenheit",
            "current_temperature" => 61.2,
            "daily_temperatures" => [
              { "date" => "2026-10-21", "high" => 66.4, "low" => 50.1 },
              { "date" => "2026-10-22", "high" => 68.0, "low" => 52.3 }
            ]
          }
        )
      end

      it "calls Nominatim and Open-Meteo once with the expected parameters" do
        get_forecast

        expect(nominatim_stub).to have_been_requested.once
        expect(open_meteo_stub).to have_been_requested.once
      end

      context "and the same forecast was requested before" do
        before { get api_v1_forecast_path, params: params }

        it "returns the forecast from the cache without calling Open-Meteo again" do
          get_forecast

          expect(response.parsed_body).to include("from_cache" => true)
          expect(open_meteo_stub).to have_been_requested.once
        end
      end
    end

    context "when Nominatim finds nothing" do
      before { nominatim_stub.to_return(status: 200, body: "[]") }

      it "responds with unprocessable content without calling Open-Meteo" do
        get_forecast

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("error" => "Could not find a zip code for this address")
        expect(open_meteo_stub).not_to have_been_requested
      end
    end

    context "when Nominatim times out" do
      before { nominatim_stub.to_timeout }

      it "responds with bad gateway explaining the timeout" do
        get_forecast

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq("error" => "Address lookup timed out, please try again")
      end
    end

    context "when Open-Meteo fails" do
      before { nominatim_stub.to_return(status: 200, body: nominatim_response) }

      context "because it responds with an error status" do
        before { open_meteo_stub.to_return(status: 500, body: "Internal Server Error") }

        it "responds with bad gateway explaining the failure" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Could not reach the weather service")
        end
      end

      context "because it responds with something that is not JSON" do
        before { open_meteo_stub.to_return(status: 200, body: "<html>Service down</html>") }

        it "responds with bad gateway explaining the failure" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Could not reach the weather service")
        end
      end

      context "because it responds with JSON that is not an object" do
        before { open_meteo_stub.to_return(status: 200, body: "[]") }

        it "responds with bad gateway explaining the failure" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Could not reach the weather service")
        end
      end

      context "because the request timed out" do
        before { open_meteo_stub.to_timeout }

        it "responds with bad gateway explaining the timeout" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Weather service timed out, please try again")
        end
      end

      context "because the host could not be found" do
        before { open_meteo_stub.to_raise(SocketError) }

        it "responds with bad gateway explaining the failure" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Could not reach the weather service")
        end
      end

      context "because the connection was refused" do
        before { open_meteo_stub.to_raise(Errno::ECONNREFUSED) }

        it "responds with bad gateway explaining the failure" do
          get_forecast

          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body).to eq("error" => "Could not reach the weather service")
        end
      end
    end
  end
end
