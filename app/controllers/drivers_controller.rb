class DriversController < ApplicationController
  before_action :set_driver, only: [:show, :edit, :update, :destroy]

  PER_PAGE = 10

  # GET /drivers
  def index
    @drivers, @more = Driver.query limit: PER_PAGE, cursor: params[:more]
  end

  # GET /drivers/1
  def show
  end

  # GET /drivers/new
  def new
    @driver = Driver.new
  end

  # GET /drivers/1/edit
  def edit
  end

  # POST /drivers
  def create
    @driver = Driver.new(driver_params)

    if @driver.save
      redirect_to @driver, notice: 'Driver was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /drivers/1
  def update
    if @driver.update(driver_params)
      redirect_to @driver, notice: 'Driver was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /drivers/1
  def destroy
    @driver.destroy
    redirect_to drivers_url, notice: 'Driver was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver
      @driver = Driver.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def driver_params
      params[:driver]
    end
end
