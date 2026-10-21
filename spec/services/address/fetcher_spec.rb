require "rails_helper"
require "geocoder/results/nominatim"

RSpec.describe Address::Fetcher do
  subject(:fetch_address) { described_class.call(address_input) }

  let(:address_input) { build(:address_input) }
  let(:address_output) { build(:address_output) }
  let(:postal_code) { address_output.zip }
  let(:geocoder_result) { instance_double(Geocoder::Result::Nominatim, postal_code: postal_code, latitude: address_output.latitude, longitude: address_output.longitude) }

  before { allow(Geocoder).to receive(:search).and_return([ geocoder_result ]) }

  describe ".call" do
    context "when the geocoder finds the address" do
      context "with a 5-digit zip code" do
        it "returns the address with its zip code and coordinates" do
          expect(fetch_address).to have_attributes(
            full_address: address_output.full_address,
            zip: address_output.zip,
            latitude: address_output.latitude,
            longitude: address_output.longitude
          )
        end

        it "searches only in the United States" do
          fetch_address

          expect(Geocoder).to have_received(:search).with(address_input.full_address, params: { countrycodes: "us" })
        end
      end

      context "with a ZIP+4 postal code" do
        let(:postal_code) { "#{address_output.zip}-1000" }

        it "keeps only the 5-digit zip code" do
          expect(fetch_address).to have_attributes(zip: address_output.zip)
        end
      end

      context "with a postal code that is not a US zip code" do
        let(:postal_code) { "SW1A 2AA" }

        it "raises a not found error" do
          expect { fetch_address }.to raise_error(described_class::NotFoundError, "Could not find a zip code for this address")
        end
      end
    end

    context "when the geocoder fails" do
      before { allow(Geocoder).to receive(:search).and_raise(geocoder_error) }

      context "because the rate limit was reached" do
        let(:geocoder_error) { Geocoder::OverQueryLimitError }

        it "raises a service error about the rate limit" do
          expect { fetch_address }.to raise_error(described_class::ServiceError, "Address lookup rate limit reached, please try again shortly")
        end
      end

      context "because the service could not be found" do
        let(:geocoder_error) { SocketError }

        it "raises a service error about the connection" do
          expect { fetch_address }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the connection was refused" do
        let(:geocoder_error) { Errno::ECONNREFUSED }

        it "raises a service error about the connection" do
          expect { fetch_address }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the response could not be parsed" do
        let(:geocoder_error) { Geocoder::ResponseParseError.new("<html>Access blocked</html>") }

        it "raises a service error about the connection" do
          expect { fetch_address }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end

      context "because the service is unavailable" do
        let(:geocoder_error) { Geocoder::ServiceUnavailable }

        it "raises a service error about the connection" do
          expect { fetch_address }.to raise_error(described_class::ServiceError, "Could not reach the address lookup service")
        end
      end
    end
  end
end
