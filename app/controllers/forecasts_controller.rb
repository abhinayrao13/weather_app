class ForecastsController < ApplicationController
  def index
  end

  def search
    address = params[:address]
    if address.present?
      @forecast = WeatherCacheService.get_forecast(address)

      if @forecast[:error]
        flash.now[:alert] = @forecast[:error]
        render :index
      else
        render :index
      end
    else
      flash.now[:alert] = "Please enter an address."
      render :index
    end
  end
end