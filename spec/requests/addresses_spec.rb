require "rails_helper"

RSpec.describe "Addresses page", type: :request do
  subject(:get_addresses_page) { get addresses_path, params: params }

  let(:params) { { full_address: "1180 Seven Seas", units: "fahrenheit", days: 3 } }
  let(:magic_kingdom) { build(:address_output) }
  let(:addresses) { [ magic_kingdom ] }

  before { allow(Address::Searcher).to receive(:call).and_return(addresses) }

  describe "GET /addresses" do
    context "when matching addresses are found" do
      it "lists each address as an option that opens its forecast in the chosen units and days" do
        get_addresses_page

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(magic_kingdom.full_address, "#{magic_kingdom.city}, #{magic_kingdom.state}")
        option = response.parsed_body.at_css("a", text: magic_kingdom.full_address)
        expect(option["href"]).to eq(forecast_path(full_address: magic_kingdom.full_address, units: "fahrenheit", days: 3))
      end
    end

    context "when no address with a zip code is found" do
      let(:addresses) { [] }

      it "suggests searching for a street address or a zip code" do
        get_addresses_page

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No addresses with a zip code found. Try a street address or a zip code.")
      end
    end

    context "when the search is too short" do
      let(:params) { { full_address: "NY" } }

      it "shows the error in the dropdown without searching" do
        get_addresses_page

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Address must be at least #{Address::Input::MIN_LENGTH} characters")
        expect(Address::Searcher).not_to have_received(:call)
      end
    end
  end
end
