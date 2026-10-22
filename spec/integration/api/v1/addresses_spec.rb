require "rails_helper"

RSpec.describe "Addresses API v1 integration", type: :request do
  subject(:get_addresses) { get api_v1_addresses_path, params: { full_address: full_address } }

  let(:full_address) { "1180 seven seas" }
  let(:nominatim_url) { "https://nominatim.openstreetmap.org/search" }
  let(:nominatim_request) do
    {
      "q" => full_address,
      "countrycodes" => "us",
      "limit" => Address::Fetcher::MAX_RESULTS.to_s,
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
          "lat": "28.4190753",
          "lon": "-81.5817158",
          "display_name": "Magic Kingdom, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States",
          "address": { "city": "Bay Lake", "state": "Florida", "postcode": "32830" }
        },
        {
          "lat": "28.4184918",
          "lon": "-81.5791797",
          "display_name": "PeopleMover, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States",
          "address": { "city": "Bay Lake", "state": "Florida", "postcode": "32830" }
        }
      ]
    JSON
  end

  describe "GET /api/v1/addresses" do
    context "when Nominatim finds matching addresses" do
      before { nominatim_stub.to_return(status: 200, body: nominatim_response) }

      it "returns the matching addresses with their city, state, zip code and coordinates as JSON" do
        get_addresses

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "addresses" => [
            {
              "full_address" => "Magic Kingdom, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States",
              "city" => "Bay Lake",
              "state" => "Florida",
              "zip" => "32830",
              "latitude" => 28.4190753,
              "longitude" => -81.5817158
            },
            {
              "full_address" => "PeopleMover, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States",
              "city" => "Bay Lake",
              "state" => "Florida",
              "zip" => "32830",
              "latitude" => 28.4184918,
              "longitude" => -81.5791797
            }
          ]
        )
      end

      it "calls Nominatim once with the expected parameters" do
        get_addresses

        expect(nominatim_stub).to have_been_requested.once
      end
    end

    context "when Nominatim only finds cities without a zip code" do
      let(:full_address) { "Orlando" }
      let(:nominatim_response) do
        <<~JSON
          [
            {
              "lat": "28.5421109",
              "lon": "-81.3790304",
              "display_name": "Orlando, Orange County, Florida, United States",
              "address": { "city": "Orlando", "state": "Florida" }
            },
            {
              "lat": "35.9314294",
              "lon": "-97.3747668",
              "display_name": "Orlando, Logan County, Oklahoma, United States",
              "address": { "town": "Orlando", "state": "Oklahoma" }
            }
          ]
        JSON
      end

      before { nominatim_stub.to_return(status: 200, body: nominatim_response) }

      it "returns an empty list because none of them can be used for a forecast" do
        get_addresses

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq("addresses" => [])
      end
    end

    context "when Nominatim times out" do
      before { nominatim_stub.to_timeout }

      it "responds with bad gateway explaining the timeout" do
        get_addresses

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq("error" => "Address lookup timed out, please try again")
      end
    end
  end
end
