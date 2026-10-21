require "rails_helper"

RSpec.describe Forecast::Input, type: :model do
  subject(:forecast_input) { described_class.new(attributes) }

  let(:attributes) { {} }

  describe "defaults" do
    context "when no units or days are given" do
      it "uses the default units and days" do
        expect(forecast_input).to have_attributes(units: described_class::DEFAULT_UNITS, days: described_class::DEFAULT_DAYS)
      end

      it { is_expected.to be_valid }
    end
  end

  describe "units validation" do
    context "when the units are fahrenheit" do
      let(:attributes) { { units: "fahrenheit" } }

      it { is_expected.to be_valid }
    end

    context "when the units are celsius" do
      let(:attributes) { { units: "celsius" } }

      it { is_expected.to be_valid }
    end

    context "when the units are not supported" do
      let(:attributes) { { units: "kelvin" } }

      it "is invalid and lists the supported units" do
        expect(forecast_input).not_to be_valid
        expect(forecast_input.errors.full_messages).to contain_exactly("Units must be one of: fahrenheit, celsius")
      end
    end
  end

  describe "days validation" do
    context "when the days are within the allowed range" do
      context "and equal the minimum" do
        let(:attributes) { { days: 1 } }

        it { is_expected.to be_valid }
      end

      context "and equal the maximum" do
        let(:attributes) { { days: described_class::MAX_DAYS } }

        it { is_expected.to be_valid }
      end
    end

    context "when the days are outside the allowed range" do
      context "and below the minimum" do
        let(:attributes) { { days: 0 } }

        it "is invalid and reports the allowed range" do
          expect(forecast_input).not_to be_valid
          expect(forecast_input.errors.full_messages).to contain_exactly("Days must be between 1 and #{described_class::MAX_DAYS}")
        end
      end

      context "and above the maximum" do
        let(:attributes) { { days: described_class::MAX_DAYS + 1 } }

        it "is invalid and reports the allowed range" do
          expect(forecast_input).not_to be_valid
          expect(forecast_input.errors.full_messages).to contain_exactly("Days must be between 1 and #{described_class::MAX_DAYS}")
        end
      end
    end

    context "when the days are not a number" do
      let(:attributes) { { days: "abc" } }

      it "is invalid and reports the allowed range" do
        expect(forecast_input).not_to be_valid
        expect(forecast_input.errors.full_messages).to contain_exactly("Days must be between 1 and #{described_class::MAX_DAYS}")
      end
    end
  end
end
