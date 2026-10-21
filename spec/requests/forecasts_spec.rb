require "rails_helper"

RSpec.describe "Forecasts page", type: :request do
  let(:address_input) { build(:address_input) }
  let(:address_output) { build(:address_output) }
  let(:from_cache) { false }
  let(:forecast_output) { build(:forecast_output, from_cache: from_cache) }

  before do
    allow(Address::Fetcher).to receive(:call).and_return(address_output)
    allow(Forecast::CachedFetcher).to receive(:call).and_return(forecast_output)
  end

  describe "GET /" do
    it "shows the search form without looking up a forecast" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Get forecast")
      expect(Address::Fetcher).not_to have_received(:call)
    end
  end

  describe "GET /forecast" do
    subject(:get_forecast_page) { get forecast_path, params: params }

    let(:params) { { address: address_input.full_address, units: "fahrenheit", days: 2 } }

    context "when the address, units and days are valid" do
      it "shows the address, its zip code and the forecast" do
        get_forecast_page

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(address_output.full_address, address_output.zip, "61°F", "Live")
      end

      context "and the forecast comes from the cache" do
        let(:from_cache) { true }

        it "shows that the result was pulled from the cache" do
          get_forecast_page

          expect(response.body).to include("From cache")
        end
      end
    end

    context "when the submitted address is blank" do
      let(:params) { { address: "" } }

      it "shows that the address is required" do
        get_forecast_page

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Address is required")
      end
    end

    context "when the address cannot be found" do
      before { allow(Address::Fetcher).to receive(:call).and_raise(Address::Fetcher::NotFoundError, "Could not find a zip code for this address") }

      it "shows the error next to the search form" do
        get_forecast_page

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Could not find a zip code for this address", "Get forecast")
      end
    end
  end
end
