class WeatherCacheService
  CACHE_EXPIRY_TIME = 30.minutes

  def self.get_forecast(address)
    geocoding_data = GeocodingService.geocode(address)
    return { error: "Could not find location for '#{address}'." } unless geocoding_data

    zip_code = geocoding_data[:zip_code]

    cache_key = "forecast_#{zip_code}"
    cached_data = Rails.cache.read(cache_key)

    if cached_data
      Rails.logger.info "Weather data for #{zip_code} pulled from cache."
      return cached_data.merge(from_cache: true)
    end

    # If not in cache, fetch from API
    current_weather = WeatherService.fetch_current_weather(geocoding_data[:latitude], geocoding_data[:longitude])
    extended_forecast = WeatherService.fetch_extended_forecast(geocoding_data[:latitude], geocoding_data[:longitude])

    if current_weather && extended_forecast
      forecast_data = {
        current: current_weather,
        extended: extended_forecast,
        address: address, # Store the original address for display
        zip_code: zip_code, # Store the zip code for display
        from_cache: false
      }
      Rails.cache.write(cache_key, forecast_data, expires_in: CACHE_EXPIRY_TIME)
      Rails.logger.info "Weather data for #{zip_code} fetched from API and cached."
      forecast_data
    else
      { error: "Could not retrieve weather data for '#{address}'." }
    end
  end
end