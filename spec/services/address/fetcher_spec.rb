require "rails_helper"
require "geocoder/results/nominatim"

RSpec.describe Address::Fetcher do
  subject(:fetch_addresses) { described_class.call(address_input) }

  let(:address_input) { build(:address_input) }
  let(:postal_code) { "32830" }
  let(:magic_kingdom_result) do
    instance_double(
      Geocoder::Result::Nominatim,
      display_name: "Magic Kingdom, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States",
      city: "Bay Lake",
      state: "Florida",
      postal_code: postal_code,
      latitude: 28.4190753,
      longitude: -81.5817158
    )
  end
  let(:geocoder_results) { [ magic_kingdom_result ] }

  before { allow(Geocoder).to receive(:search).and_return(geocoder_results) }

  describe ".call" do
    context "when the geocoder finds matching addresses" do
      it "returns each address with its city, state, zip code and coordinates" do
        expect(fetch_addresses).to contain_exactly(
          have_attributes(
            full_address: magic_kingdom_result.display_name,
            city: "Bay Lake",
            state: "Florida",
            zip: "32830",
            latitude: 28.4190753,
            longitude: -81.5817158
          )
        )
      end

      it "searches only in the United States and limits the number of results" do
        fetch_addresses

        expect(Geocoder).to have_received(:search).with(address_input.full_address, params: { countrycodes: "us", limit: described_class::MAX_RESULTS })
      end
    end

    context "when some matches have no US zip code" do
      let(:result_without_zip_code) do
        instance_double(Geocoder::Result::Nominatim, display_name: "Bay Lake, Florida, United States", city: "Bay Lake", state: "Florida", postal_code: nil, latitude: 28.39, longitude: -81.56)
      end
      let(:geocoder_results) { [ magic_kingdom_result, result_without_zip_code ] }

      it "returns only the addresses with a zip code" do
        expect(fetch_addresses).to contain_exactly(have_attributes(full_address: magic_kingdom_result.display_name))
      end
    end

    context "when a match has a ZIP+4 postal code" do
      let(:postal_code) { "32830-1000" }

      it "keeps only the 5-digit zip code" do
        expect(fetch_addresses).to contain_exactly(have_attributes(zip: "32830"))
      end
    end

    context "when a match has a postal code that is not a US zip code" do
      let(:postal_code) { "SW1A 2AA" }

      it "leaves it out of the results" do
        expect(fetch_addresses).to be_empty
      end
    end

    context "when the geocoder fails" do
      before { allow(Geocoder).to receive(:search).and_raise(geocoder_error) }

      context "because the rate limit was reached" do
        let(:geocoder_error) { Geocoder::OverQueryLimitError }

        it "raises a service error about the rate limit" do
          expect { fetch_addresses }.to raise_error(described_class::ServiceError, "Address lookup rate limit reached, please try again shortly")
        end
      end

      context "because the service could not be found" do
        let(:geocoder_error) { SocketError }

        it "raises a service error about the connection" do
          expect { fetch_addresses }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the connection was refused" do
        let(:geocoder_error) { Errno::ECONNREFUSED }

        it "raises a service error about the connection" do
          expect { fetch_addresses }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the response could not be parsed" do
        let(:geocoder_error) { Geocoder::ResponseParseError.new("<html>Access blocked</html>") }

        it "raises a service error about the connection" do
          expect { fetch_addresses }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the service is unavailable" do
        let(:geocoder_error) { Geocoder::ServiceUnavailable }

        it "raises a service error about the connection" do
          expect { fetch_addresses }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end
    end
  end
end
