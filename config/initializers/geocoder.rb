Geocoder.configure(
  timeout: 5,                   # geocoding service timeout (secs)
  lookup: :nominatim,           # name of geocoding service (symbol)
  # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  language: :en,                # ISO-639 language code
  use_https: true,              # use HTTPS for lookup requests? (if supported)
  http_headers: { "User-Agent" => "rails-weather-forecast (https://github.com/nascimentoleo/rails-weather-forecast)" },
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)
  # api_key: nil,               # API key for geocoding service
  # cache: nil,                 # cache object (must respond to #[], #[]=, and #del)

  # Exceptions that should not be rescued by default
  # supports SocketError and Timeout::Error
  always_raise: :all,

  # Calculation options
  # units: :mi,                 # :km for kilometers or :mi for miles
  # distances: :linear          # :spherical or :linear

  # Cache configuration
  # cache_options: {
  #   expiration: 2.days,
  #   prefix: 'geocoder:'
  # }
)
