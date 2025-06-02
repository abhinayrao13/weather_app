# WeatherApp: Address-Based Forecast App

WeatherApp is a Ruby on Rails application that allows users to retrieve current and extended weather forecasts for any given address. It leverages external APIs for geocoding and weather data, and implements robust caching with Redis to ensure fast, efficient responses for repeat requests.

---

## Features

* **Address Input:** Easily get forecasts by typing in any valid address.
* **Current Weather:** Displays real-time temperature, "feels like" temperature, and daily high/low.
* **Extended Forecast:** Provides a 5-day outlook with daily high/low temperatures and descriptions.
* **Intelligent Caching:** Forecast data is cached for 30 minutes based on zip code, significantly speeding up subsequent requests for the same area.
* **Cache Indicator:** Clearly indicates if the displayed forecast was pulled from the cache.
* **Robust Error Handling:** Gracefully manages invalid addresses or issues with API communication.

---

## Technologies Used

* **Ruby on Rails:** The core web application framework.
* **Faraday:** For making HTTP requests to external APIs.
* **Geocoder Gem:** Converts addresses to geographical coordinates (latitude, longitude, and zip code).
* **Redis:** Used as the caching store for forecast data in both development and production.
* **OpenWeatherMap API:** Provides current and extended weather forecast data.
* **Geoapify Geocoding API:** Converts addresses to geographical coordinates.

---

## Setup and Installation

Follow these steps to get WeatherApp up and running on your local machine.

### 1. Prerequisites

Before you begin, ensure you have the following installed:

* **Ruby (3.0+ recommended):** [ruby-lang.org](https://www.ruby-lang.org/en/downloads/)
* **Rails (7.0+ recommended):** `gem install rails`
* **Bundler:** `gem install bundler`
* **Redis:**
    * **Linux/Windows:** Refer to the [official Redis documentation](https://redis.io/docs/getting-started/installation/) for installation instructions.
    * **Verify Redis:** After installation, you should be able to run `sudo systemctl start redis-server` and get status `sudo systemctl status redis-server`.
    * **Clear Cache:** You should run `redis-cli flushall`

### 2. Get API Keys

This application relies on external APIs. You'll need to obtain free API keys from:

* **OpenWeatherMap:** [openweathermap.org](https://openweathermap.org/api) (Choose the "Current Weather Data" and "5 Day / 3 Hour Forecast" APIs).
* **Geoapify Geocoding API:** [www.geoapify.com](https://www.geoapify.com/) (Sign up and get an API key for their Geocoding API).

### 3. Clone the Repository

```bash
git clone git@github.com:abhinayrao13/weather_app.git
cd weather_app