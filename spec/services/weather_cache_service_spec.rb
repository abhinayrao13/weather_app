# spec/facades/weather_facade_spec.rb
require 'rails_helper'

RSpec.describe WeatherCacheService, type: :facade do
  let(:address) { "123 Cache St, Anytown, CA" }
  let(:zip_code) { "90210" }
  let(:latitude) { 34.0736 }
  let(:longitude) { -118.4004 }

  let(:geocoding_success_response) do
    { latitude: latitude, longitude: longitude, zip_code: zip_code }
  end

  let(:current_weather_data) do
    { temperature: 70.0, feels_like: 69.0, temp_min: 65.0, temp_max: 75.0, description: "sunny", city_name: "Anytown" }
  end

  let(:extended_forecast_data) do
    [
      { date: "Monday, Jan 01", temp_min: 50, temp_max: 70, description: "clear sky" },
      { date: "Tuesday, Jan 02", temp_min: 55, temp_max: 75, description: "partly cloudy" }
    ]
  end

  # Mock API key lookups for services
  before do
    allow(Rails.application.credentials).to receive(:dig).with(Rails.env, :geoapify_api_key).and_return("test_geoapify_key")
    allow(Rails.application.credentials).to receive(:dig).with(Rails.env, :weather_api_key).and_return("test_weather_api_key")
  end

  # Clear cache before each test to ensure fresh state
  before(:each) do
    Rails.cache.clear
  end

  describe '.get_forecast' do
    context 'when geocoding is successful and weather data is fetched' do
      before do
        allow(GeocodingService).to receive(:geocode).with(address).and_return(geocoding_success_response)
        allow(WeatherService).to receive(:fetch_current_weather).with(latitude, longitude).and_return(current_weather_data)
        allow(WeatherService).to receive(:fetch_extended_forecast).with(latitude, longitude).and_return(extended_forecast_data)
      end

      it 'fetches and returns forecast data from APIs on first call' do
        forecast = WeatherCacheService.get_forecast(address)

        expect(forecast).to be_a(Hash)
        expect(forecast[:current]).to eq(current_weather_data)
        expect(forecast[:extended]).to eq(extended_forecast_data)
        expect(forecast[:address]).to eq(address)
        expect(forecast[:zip_code]).to eq(zip_code)
        expect(forecast[:from_cache]).to be(false)
      end

      it 'caches the forecast data for subsequent requests' do
        # First call: should fetch from API
        forecast = WeatherCacheService.get_forecast(address)

        # Second call: should read from cache
        allow(Rails.cache).to receive(:read).with("forecast_#{zip_code}").and_return(forecast)
        cached_forecast = WeatherCacheService.get_forecast(address)
        expect(GeocodingService).not_to receive(:geocode) # Should not call geocoding again
        expect(WeatherService).not_to receive(:fetch_current_weather) # Should not call weather API again
        expect(WeatherService).not_to receive(:fetch_extended_forecast) # Should not call weather API again

        expect(cached_forecast[:from_cache]).to be(true)
        expect(cached_forecast[:current]).to eq(current_weather_data)
      end

      it 're-fetches data after cache expiry' do
        # First call: populate cache
        WeatherCacheService.get_forecast(address)

        # Advance time beyond cache expiry
        travel_to(WeatherCacheService::CACHE_EXPIRY_TIME.from_now + 1.minute) do
          # Expect API calls to happen again
          expect(GeocodingService).to receive(:geocode).with(address).and_return(geocoding_success_response)
          expect(WeatherService).to receive(:fetch_current_weather).with(latitude, longitude).and_return(current_weather_data)
          expect(WeatherService).to receive(:fetch_extended_forecast).with(latitude, longitude).and_return(extended_forecast_data)

          refetched_forecast = WeatherCacheService.get_forecast(address)
          expect(refetched_forecast[:from_cache]).to be(false)
        end
      end
    end

    context 'when geocoding fails' do
      before do
        allow(GeocodingService).to receive(:geocode).with(address).and_return(nil)
      end

      it 'returns an error hash' do
        forecast = WeatherCacheService.get_forecast(address)
        expect(forecast).to eq({ error: "Could not find location for '#{address}'." })
      end

      it 'does not attempt to fetch weather data' do
        expect(WeatherService).not_to receive(:fetch_current_weather)
        expect(WeatherService).not_to receive(:fetch_extended_forecast)
        WeatherCacheService.get_forecast(address)
      end
    end

    context 'when weather data fetching fails' do
      before do
        allow(GeocodingService).to receive(:geocode).with(address).and_return(geocoding_success_response)
        allow(WeatherService).to receive(:fetch_current_weather).and_return(nil) # Simulate failure
        allow(WeatherService).to receive(:fetch_extended_forecast).and_return(extended_forecast_data) # One might fail, the other succeed
      end

      it 'returns an error hash' do
        forecast = WeatherCacheService.get_forecast(address)
        expect(forecast).to eq({ error: "Could not retrieve weather data for '#{address}'." })
      end

      it 'does not cache the result' do
        expect(Rails.cache).not_to receive(:write)
        WeatherCacheService.get_forecast(address)
      end
    end
  end
end