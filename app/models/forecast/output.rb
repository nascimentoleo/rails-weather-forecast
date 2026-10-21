module Forecast
  class Output
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :units, :string
    attribute :current_temperature, :float
    attribute :daily_temperatures, default: -> { [] }
    attribute :from_cache, :boolean, default: false
  end
end
