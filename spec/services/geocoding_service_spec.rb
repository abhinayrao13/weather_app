require 'rails_helper'

RSpec.describe GeocodingService, type: :service do
  let(:valid_address) { "1600 Amphitheatre Parkway, Mountain View, CA" }
  let(:invalid_address) { "NonExistentAddress123" }
  let(:mock_latitude) { 37.422 }
  let(:mock_longitude) { -122.084 }
  let(:mock_postal_code) { "94043" }

  # Mock Geocoder.search to control its behavior during tests
  before do
    # Stub the API key lookup for tests
    allow(Rails.application.credentials).to receive(:dig).with(Rails.env, :geoapify_api_key).and_return("test_geoapify_key")

    # Mock a successful geocoding result
    allow(Geocoder).to receive(:search).with(valid_address).and_return([
      double("GeocoderResult",
        latitude: mock_latitude,
        longitude: mock_longitude,
        postal_code: mock_postal_code
      )
    ])

    # Mock an unsuccessful geocoding result
    allow(Geocoder).to receive(:search).with(invalid_address).and_return([])
  end

  describe '.geocode' do
    context 'with a valid address' do
      it 'returns latitude, longitude, and zip code' do
        result = GeocodingService.geocode(valid_address)
        expect(result).to be_a(Hash)
        expect(result[:latitude]).to eq(mock_latitude)
        expect(result[:longitude]).to eq(mock_longitude)
        expect(result[:zip_code]).to eq(mock_postal_code)
      end
    end

    context 'with an invalid address' do
      it 'returns nil' do
        result = GeocodingService.geocode(invalid_address)
        expect(result).to be_nil
      end
    end

    context 'when Geocoder API raises an OverQueryLimitError' do
      before do
        allow(Geocoder).to receive(:search).and_raise(Geocoder::OverQueryLimitError)
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with("Geocoder API rate limit exceeded.")
        result = GeocodingService.geocode(valid_address)
        expect(result).to be_nil
      end
    end

    context 'when Geocoder API raises a generic error' do
      before do
        allow(Geocoder).to receive(:search).and_raise(StandardError, "Network error")
      end

      it 'returns nil and logs an error' do
        expect(Rails.logger).to receive(:error).with("Geocoding error for address '#{valid_address}': Network error")
        result = GeocodingService.geocode(valid_address)
        expect(result).to be_nil
      end
    end
  end
end