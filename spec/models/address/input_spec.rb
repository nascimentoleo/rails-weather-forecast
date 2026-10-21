require "rails_helper"

RSpec.describe Address::Input, type: :model do
  subject(:address_input) { described_class.new(attributes) }

  let(:attributes) { { full_address: "1180 Seven Seas Dr" } }

  describe "validations" do
    context "when the full address is present" do
      it { is_expected.to be_valid }
    end

    context "when the full address is missing" do
      let(:attributes) { { full_address: nil } }

      it "is invalid and reports that the address is required" do
        expect(address_input).not_to be_valid
        expect(address_input.errors.full_messages).to contain_exactly("Address is required")
      end
    end

    context "when the full address is empty" do
      let(:attributes) { { full_address: "" } }

      it "is invalid and reports that the address is required" do
        expect(address_input).not_to be_valid
        expect(address_input.errors.full_messages).to contain_exactly("Address is required")
      end
    end

    context "when the full address has only whitespace and control characters" do
      let(:attributes) { { full_address: " \t\n\u0000 " } }

      it "is invalid and reports that the address is required" do
        expect(address_input).not_to be_valid
        expect(address_input.errors.full_messages).to contain_exactly("Address is required")
      end
    end

    context "when the full address has exactly the maximum length" do
      let(:attributes) { { full_address: "a" * described_class::MAX_LENGTH } }

      it { is_expected.to be_valid }
    end

    context "when the full address is longer than the maximum length" do
      let(:attributes) { { full_address: "a" * (described_class::MAX_LENGTH + 1) } }

      it "is invalid and reports the maximum length" do
        expect(address_input).not_to be_valid
        expect(address_input.errors.full_messages).to contain_exactly("Address must be at most #{described_class::MAX_LENGTH} characters")
      end
    end
  end

  describe "normalization" do
    context "when the full address has control characters and extra whitespace" do
      let(:attributes) { { full_address: "\t1180\u0000Seven\n   Seas Dr  " } }

      it "replaces control characters with spaces and collapses whitespace" do
        expect(address_input.full_address).to eq("1180 Seven Seas Dr")
      end
    end
  end
end
