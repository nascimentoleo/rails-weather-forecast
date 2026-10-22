FactoryBot.define do
  factory :forecast_input, class: "Forecast::Input"

  factory :forecast_output, class: "Forecast::Output" do
    units { "fahrenheit" }
    current_temperature { 61.2 }
    daily_temperatures do
      [
        { date: "2026-10-21", high: 66.4, low: 50.1 },
        { date: "2026-10-22", high: 68.0, low: 52.3 }
      ]
    end
  end
end
