FactoryBot.define do
  factory :address_input, class: "Address::Input" do
    full_address { "1180 Seven Seas Dr" }

    initialize_with { new(attributes) }
  end

  factory :address_output, class: "Address::Output" do
    full_address { "1180 Seven Seas Dr" }
    zip { "32830" }
    latitude { 28.4177 }
    longitude { -81.5812 }

    initialize_with { new(attributes) }

    trait :white_house do
      full_address { "1600 Pennsylvania Ave" }
      zip { "20500" }
      latitude { 38.8977 }
      longitude { -77.0365 }
    end
  end
end
