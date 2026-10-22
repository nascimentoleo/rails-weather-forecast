require "rails_helper"

RSpec.describe "Addresses API v1", type: :request do
  subject(:get_addresses) { get api_v1_addresses_path, params: params }

  let(:params) { { query: "1180 Seven Seas" } }
  let(:magic_kingdom) { build(:address_output) }
  let(:white_house) { build(:address_output, :white_house) }

  before { allow(Address::Searcher).to receive(:call).and_return([ magic_kingdom, white_house ]) }

  describe "GET /api/v1/addresses" do
    context "when the query is valid" do
      it "returns the matching addresses with their city, state, zip code and coordinates as JSON" do
        get_addresses

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "addresses" => [
            magic_kingdom.attributes.slice("full_address", "city", "state", "zip", "latitude", "longitude"),
            white_house.attributes.slice("full_address", "city", "state", "zip", "latitude", "longitude")
          ]
        )
      end

      it "searches for the requested address" do
        get_addresses

        expect(Address::Searcher).to have_received(:call).with(having_attributes(full_address: "1180 Seven Seas"))
      end
    end

    context "when the query is missing" do
      let(:params) { {} }

      it "responds with bad request without searching" do
        get_addresses

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "Query is required")
        expect(Address::Searcher).not_to have_received(:call)
      end
    end

    context "when the query is too short" do
      let(:params) { { query: "NY" } }

      it "responds with bad request without searching" do
        get_addresses

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("error" => "Address must be at least #{Address::Input::MIN_LENGTH} characters")
        expect(Address::Searcher).not_to have_received(:call)
      end
    end
  end
end
