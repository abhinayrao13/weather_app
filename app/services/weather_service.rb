class WeatherService
  BASE_URL = "https://api.openweathermap.org/data/2.5/weather" # For current weather
  FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast" # For 5-day forecast
  API_KEY = Rails.application.credentials.dig(Rails.env, :weather_api_key)

  def self.fetch_current_weather(latitude, longitude)
    url = "#{BASE_URL}?lat=#{latitude}&lon=#{longitude}&appid=#{API_KEY}&units=metric" # units=metric for Celcius
    response = Faraday.get(url)
    if response.success?
      data = JSON.parse(response.body)
      parse_current_weather(data)
    else
      Rails.logger.error "OpenWeatherMap API error: #{response.status} - #{response.body}"
    end
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error "Connection to OpenWeatherMap failed: #{e.message}"
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse OpenWeatherMap response: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "An unexpected error occurred during weather fetch: #{e.message}"
  end

  def self.fetch_extended_forecast(latitude, longitude)
    url = "#{FORECAST_URL}?lat=#{latitude}&lon=#{longitude}&appid=#{API_KEY}&units=metric"
    response = Faraday.get(url)
    if response.success?
      data = JSON.parse(response.body)
      parse_extended_forecast(data)
    else
      Rails.logger.error "OpenWeatherMap Forecast API error: #{response.status} - #{response.body}"
    end
  rescue StandardError => e
    Rails.logger.error "An unexpected error occurred during extended forecast fetch: #{e.message}"
  end


  private

  def self.parse_current_weather(data)
    {
      temperature: data['main']['temp'],
      feels_like: data['main']['feels_like'],
      temp_min: data['main']['temp_min'],
      temp_max: data['main']['temp_max'],
      description: data['weather'][0]['description'],
      city_name: data['name']
    }
  end

  def self.parse_extended_forecast(data)
    forecasts = []
    # OpenWeatherMap's 5-day forecast is in 3-hour steps.
    # We'll pick one entry per day for simplicity for high/low.
    data['list'].each_slice(8) do |day_forecasts| # 8 entries per day (3 hours * 8 = 24 hours)
      next unless day_forecasts.first # Skip if no data for the day
      day_data = day_forecasts.map { |f| f['main']['temp'] }
      forecasts << {
        date: Time.at(day_forecasts.first['dt']).strftime('%A, %b %d'),
        temp_min: day_data.min,
        temp_max: day_data.max,
        description: day_forecasts.first['weather'][0]['description']
      }
    end
    forecasts.take(5) # Get next 5 days
  end
end