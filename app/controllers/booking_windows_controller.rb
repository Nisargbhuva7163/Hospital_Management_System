class BookingWindowsController < ApplicationController
  before_action :set_organization
  before_action :set_booking_window, only: [ :show, :destroy ]

  # GET /organizations/:organization_id/booking_windows/new
  def new
    @booking_window = @organization.booking_windows.new
    @booking_windows = @organization.booking_windows.order(created_at: :desc)
  end

  # POST /organizations/:organization_id/booking_windows
  def create
    @booking_window = @organization.booking_windows.new(booking_window_params)
    if @booking_window.save
      redirect_to new_organization_booking_window_path(@organization), notice: "Booking window created successfully."
    else
      @booking_windows = @organization.booking_windows.order(created_at: :desc)
      render :new
    end
  end

  # GET /organizations/:organization_id/booking_windows/:id
  def show
    # @booking_window is already set by before_action
  end

  # DELETE /organizations/:organization_id/booking_windows/:id
  def destroy
    if @booking_window
      @booking_window.destroy
      flash[:notice] = "Booking window deleted."
    else
      flash[:alert] = "Booking window not found."
    end
    redirect_to new_organization_booking_window_path(@organization)
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_booking_window
    @booking_window = @organization.booking_windows.find_by(id: params[:id])
  end

  def booking_window_params
    params.require(:booking_window).permit(:start_time, :end_time)
  end
end
