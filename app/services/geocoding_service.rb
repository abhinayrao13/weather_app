class GeocodingService
  def self.geocode(address)
    results = Geocoder.search(address)
    if results.any?
      # Return latitude, longitude, and zip code
      {
        latitude: results.first.latitude,
        longitude: results.first.longitude,
        zip_code: results.first.postal_code
      }
    end
  rescue Geocoder::OverQueryLimitError
    Rails.logger.error "Geocoder API rate limit exceeded."
  rescue StandardError => e
    Rails.logger.error "Geocoding error for address '#{address}': #{e.message}"
  end
end