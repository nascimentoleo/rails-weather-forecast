require "rails_helper"

RSpec.describe Forecast::CachedFetcher do
  include ActiveSupport::Testing::TimeHelpers

  subject(:fetch_cached_forecast) { described_class.call(address_output: address_output, forecast_input: forecast_input) }

  let(:address_output) { build(:address_output) }
  let(:forecast_input) { build(:forecast_input, units: "celsius", days: 3) }
  let(:original_cache) { Rails.cache }
  let(:forecast_output) { build(:forecast_output) }

  before do
    original_cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    allow(Forecast::Fetcher).to receive(:call).and_return(forecast_output)
  end

  after { Rails.cache = original_cache }

  describe ".call" do
    context "when the forecast is not cached yet" do
      it "fetches the forecast from the weather service and marks it as not from cache" do
        expect(fetch_cached_forecast).to have_attributes(current_temperature: forecast_output.current_temperature, from_cache: false)
        expect(Forecast::Fetcher).to have_received(:call).with(address: address_output, forecast_input: forecast_input).once
      end

      it "caches it with the configured expiration and protection against simultaneous refreshes" do
        allow(Rails.cache).to receive(:fetch).and_call_original

        fetch_cached_forecast

        expect(Rails.cache).to have_received(:fetch).with(anything, hash_including(**Rails.configuration.cache_options))
      end
    end

    context "when a forecast was cached before" do
      let(:cached_address_output) { address_output }
      let(:cached_forecast_input) { forecast_input }

      before { described_class.call(address_output: cached_address_output, forecast_input: cached_forecast_input) }

      context "with the same address, units and days" do
        it "returns the cached forecast without fetching it again" do
          expect(fetch_cached_forecast).to have_attributes(current_temperature: forecast_output.current_temperature, from_cache: true)
          expect(Forecast::Fetcher).to have_received(:call).once
        end

        context "and the expiration time has not passed yet" do
          it "returns the cached forecast" do
            travel(Rails.configuration.cache_options[:expires_in] - 1.second) do
              expect(fetch_cached_forecast).to have_attributes(from_cache: true)
            end
          end
        end

        context "and the expiration time has passed" do
          it "fetches a new forecast" do
            travel(Rails.configuration.cache_options[:expires_in] + 1.second) do
              expect(fetch_cached_forecast).to have_attributes(from_cache: false)
            end
          end
        end
      end

      context "with a different address in the same zip code" do
        let(:cached_address_output) { build(:address_output, full_address: "1375 E Buena Vista Dr") }

        it "returns the cached forecast for that zip code" do
          expect(fetch_cached_forecast).to have_attributes(from_cache: true)
        end
      end

      context "with a different zip code" do
        let(:cached_address_output) { build(:address_output, :white_house) }

        it "fetches a new forecast" do
          expect(fetch_cached_forecast).to have_attributes(from_cache: false)
        end
      end

      context "with the same zip code but different units" do
        let(:cached_forecast_input) { build(:forecast_input, units: "fahrenheit", days: 3) }

        it "fetches a new forecast" do
          expect(fetch_cached_forecast).to have_attributes(from_cache: false)
        end
      end

      context "with the same zip code but different days" do
        let(:cached_forecast_input) { build(:forecast_input, units: "celsius", days: 7) }

        it "fetches a new forecast" do
          expect(fetch_cached_forecast).to have_attributes(from_cache: false)
        end
      end
    end
  end
end
