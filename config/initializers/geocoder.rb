Geocoder.configure(
  # Geocoding service (e.g., :google, :nominatim, :mapbox)
  # Choose one that suits your needs. Nominatim is free but has usage limits.
  # Google requires an API key.
  lookup: :geoapify, # or :nominatim
  api_key: Rails.application.credentials.dig(Rails.env, :geocoding_api_key), # if using credentials
  timeout: 5,
  # set default units to kilometers:
  units: :imperial, # or :km for metric
)