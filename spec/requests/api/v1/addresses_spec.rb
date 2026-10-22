require "swagger_helper"

RSpec.describe "Addresses API v1", type: :request do
  let(:magic_kingdom) { build(:address_output) }
  let(:white_house) { build(:address_output, :white_house) }

  before { allow(Address::CachedFetcher).to receive(:call).and_return([ magic_kingdom, white_house ]) }

  path "/api/v1/addresses" do
    get "Searches US addresses that have a zip code" do
      tags "Addresses"
      produces "application/json"
      parameter name: :full_address, in: :query, required: true,
                description: "Address to search for", example: "1180 Seven Seas Dr", schema: { type: :string }

      response "200", "matching addresses" do
        schema type: :object,
               properties: { addresses: { type: :array, items: { "$ref" => "#/components/schemas/address" } } },
               required: %w[addresses]

        let(:full_address) { "1180 Seven Seas" }

        run_test! "returns the addresses matching the search with their city, state, zip code and coordinates" do
          expect(Address::CachedFetcher).to have_received(:call).with(having_attributes(full_address: "1180 Seven Seas"))
          expect(response.parsed_body).to eq(
            "addresses" => [
              magic_kingdom.attributes.slice("full_address", "city", "state", "zip", "latitude", "longitude"),
              white_house.attributes.slice("full_address", "city", "state", "zip", "latitude", "longitude")
            ]
          )
        end
      end

      response "400", "invalid full address" do
        schema "$ref" => "#/components/schemas/error"

        context "when the full address is missing" do
          let(:full_address) { nil }

          run_test! "responds with bad request without searching" do
            expect(response.parsed_body).to eq("error" => "Full address is required")
            expect(Address::CachedFetcher).not_to have_received(:call)
          end
        end

        context "when the search is too short" do
          let(:full_address) { "NY" }

          run_test! "responds with bad request without searching" do
            expect(response.parsed_body).to eq("error" => "Address must be at least #{Address::Input::MIN_LENGTH} characters")
            expect(Address::CachedFetcher).not_to have_received(:call)
          end
        end
      end

      response "502", "address lookup service failed" do
        schema "$ref" => "#/components/schemas/error"

        let(:full_address) { "1180 Seven Seas" }

        before { allow(Address::CachedFetcher).to receive(:call).and_raise(Address::Fetcher::ServiceError, "Address lookup timed out, please try again") }

        run_test! "explains the failure" do
          expect(response.parsed_body).to eq("error" => "Address lookup timed out, please try again")
        end
      end
    end
  end
end
