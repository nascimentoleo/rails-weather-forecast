require "rails_helper"

RSpec.describe Address::CachedFetcher do
  include ActiveSupport::Testing::TimeHelpers

  subject(:fetch_cached_addresses) { described_class.call(address_input) }

  let(:address_input) { build(:address_input, full_address: "1180 Seven Seas Dr") }
  let(:magic_kingdom) { build(:address_output, full_address: "Magic Kingdom, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States") }
  let(:people_mover) { build(:address_output, full_address: "PeopleMover, 1180, Seven Seas Drive, Bay Lake, Florida, 32830, United States") }
  let(:original_cache) { Rails.cache }

  before do
    original_cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    allow(Address::Fetcher).to receive(:call).and_return([ magic_kingdom, people_mover ])
  end

  after { Rails.cache = original_cache }

  describe ".call" do
    context "when the search is not cached yet" do
      it "fetches the addresses from the address lookup service and marks them as not from cache" do
        expect(fetch_cached_addresses.map(&:attributes)).to eq([ magic_kingdom.attributes, people_mover.attributes ])
        expect(fetch_cached_addresses).to all(have_attributes(from_cache: false))
        expect(Address::Fetcher).to have_received(:call).with(address_input).once
      end

      it "caches them with the configured expiration and protection against simultaneous refreshes" do
        allow(Rails.cache).to receive(:fetch).and_call_original

        fetch_cached_addresses

        expect(Rails.cache).to have_received(:fetch).with(anything, hash_including(**Rails.configuration.cache_options))
      end
    end

    context "when a search was cached before" do
      let(:cached_full_address) { address_input.full_address }

      before { described_class.call(build(:address_input, full_address: cached_full_address)) }

      context "with the same search" do
        it "returns the cached addresses marked as from cache without fetching them again" do
          expect(fetch_cached_addresses).to contain_exactly(
            have_attributes(full_address: magic_kingdom.full_address, from_cache: true),
            have_attributes(full_address: people_mover.full_address, from_cache: true)
          )
          expect(Address::Fetcher).to have_received(:call).once
        end

        context "and the expiration time has not passed yet" do
          it "returns the cached addresses" do
            travel(Rails.configuration.cache_options[:expires_in] - 1.second) do
              expect(fetch_cached_addresses).to all(have_attributes(from_cache: true))
            end
          end
        end

        context "and the expiration time has passed" do
          it "fetches the addresses again" do
            travel(Rails.configuration.cache_options[:expires_in] + 1.second) do
              expect(fetch_cached_addresses).to all(have_attributes(from_cache: false))
            end

            expect(Address::Fetcher).to have_received(:call).twice
          end
        end
      end

      context "with the same search in a different letter case" do
        let(:cached_full_address) { "1180 SEVEN SEAS DR" }

        it "returns the cached addresses without fetching them again" do
          expect(fetch_cached_addresses).to all(have_attributes(from_cache: true))
          expect(Address::Fetcher).to have_received(:call).once
        end
      end

      context "and one of its addresses is searched by its full address" do
        subject(:fetch_cached_addresses) { described_class.call(build(:address_input, full_address: people_mover.full_address)) }

        it "returns only that address from the cache without fetching it again" do
          expect(fetch_cached_addresses).to contain_exactly(have_attributes(full_address: people_mover.full_address, zip: people_mover.zip, from_cache: true))
          expect(Address::Fetcher).to have_received(:call).once
        end
      end
    end

    context "when the address lookup service fails" do
      before { allow(Address::Fetcher).to receive(:call).and_raise(Address::Fetcher::ServiceError, "Address lookup timed out, please try again") }

      it "does not cache the failure, so the next search tries again" do
        expect { fetch_cached_addresses }.to raise_error(Address::Fetcher::ServiceError)
        expect { fetch_cached_addresses }.to raise_error(Address::Fetcher::ServiceError)
        expect(Address::Fetcher).to have_received(:call).twice
      end
    end
  end
end
