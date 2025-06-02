# spec/services/weather_service_spec.rb
require 'rails_helper'
require 'faraday'
require 'json'

RSpec.describe WeatherService, type: :service do
  let(:latitude) { 37.422 }
  let(:longitude) { -122.084 }
  let(:api_key) { "test_weather_api_key" }

  # Mock API key lookup
  before do
    allow(Rails.application.credentials).to receive(:dig).with(Rails.env, :weather_api_key).and_return(api_key)
  end

  describe '.fetch_current_weather' do
    let(:current_weather_response_body) do
      {
        "main" => {
          "temp" => 75.5,
          "feels_like" => 76.0,
          "temp_min" => 70.0,
          "temp_max" => 80.0
        },
        "weather" => [
          { "description" => "clear sky" }
        ],
        "name" => "Mountain View"
      }.to_json
    end

    context 'when the API call is successful' do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/weather/)
          .to_return(status: 200, body: current_weather_response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns parsed current weather data' do
        weather_data = WeatherService.fetch_current_weather(latitude, longitude)
        expect(weather_data).to be_a(Hash)
        expect(weather_data[:temperature]).to eq(75.5)
        expect(weather_data[:feels_like]).to eq(76.0)
        expect(weather_data[:temp_min]).to eq(70.0)
        expect(weather_data[:temp_max]).to eq(80.0)
        expect(weather_data[:description]).to eq("clear sky")
        expect(weather_data[:city_name]).to eq("Mountain View")
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/weather/)
          .to_return(status: 401, body: '{"message":"Unauthorized"}')
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with(/OpenWeatherMap API error: 401 - {"message":"Unauthorized"}/)
        weather_data = WeatherService.fetch_current_weather(latitude, longitude)
        expect(weather_data).to be_nil
      end
    end

    context 'when there is a network connection error' do
      before do
        allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed, "Failed to connect")
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with(/Connection to OpenWeatherMap failed: Failed to connect/)
        weather_data = WeatherService.fetch_current_weather(latitude, longitude)
        expect(weather_data).to be_nil
      end
    end

    context 'when the JSON response is invalid' do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/weather/)
          .to_return(status: 200, body: 'invalid json', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with("Failed to parse OpenWeatherMap response: unexpected character: 'invalid' at line 1 column 1")
        weather_data = WeatherService.fetch_current_weather(latitude, longitude)
        expect(weather_data).to be_nil
      end
    end
  end

  describe '.fetch_extended_forecast' do
    let(:extended_forecast_response_body) do
      {
        "list" => [
          { "dt" => Time.now.to_i, "main" => { "temp" => 70, "temp_min" => 65, "temp_max" => 75 }, "weather" => [{ "description" => "light rain" }] },
          { "dt" => (Time.now + 3.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 6.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 9.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 12.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 15.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 18.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 21.hours).to_i, "main" => { "temp" => 72, "temp_min" => 68, "temp_max" => 78 }, "weather" => [{ "description" => "cloudy" }] },
          { "dt" => (Time.now + 24.hours).to_i, "main" => { "temp" => 60, "temp_min" => 55, "temp_max" => 65 }, "weather" => [{ "description" => "sunny" }] }
        ]
      }.to_json
    end

    context 'when the API call is successful' do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/forecast/)
          .to_return(status: 200, body: extended_forecast_response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns parsed extended forecast data for 5 days' do
        forecast_data = WeatherService.fetch_extended_forecast(latitude, longitude)
        expect(forecast_data).to be_an(Array)
        expect(forecast_data.size).to eq(2) # Expecting 2 days
        expect(forecast_data.first).to have_key(:date)
        expect(forecast_data.first).to have_key(:temp_min)
        expect(forecast_data.first).to have_key(:temp_max)
        expect(forecast_data.first).to have_key(:description)
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/forecast/)
          .to_return(status: 500, body: '{"message":"Internal Server Error"}')
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with(/OpenWeatherMap Forecast API error: 500 - {"message":"Internal Server Error"}/)
        forecast_data = WeatherService.fetch_extended_forecast(latitude, longitude)
        expect(forecast_data).to be_nil
      end
    end
  end
end