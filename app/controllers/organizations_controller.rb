class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :index, :toggle_doctor_status, :booking_window, :update ]
  def index
    unless @organization
      redirect_to root_path, alert: "Access denied."
      return
    end

    @current_token_appointment = @organization.appointments.where.not(status: "completed").order(created_at: :asc).first

    # Check if all appointments are completed
      @total_appointments_count = @organization.appointments.count


    @last_token_appointment = @organization.appointments.order(token_no: :desc).first
  end

  def toggle_doctor_status
    if @organization.checked_in?
      @organization.update(doctor_status: "checked_out")
    else
      @organization.update(doctor_status: "checked_in")
    end

    respond_to do |format|
      format.html { redirect_to organizations_path, notice: "Doctor status updated." }
      format.js   # optional: for AJAX
    end
  end

  def booking_window
  end

  def update
    if @organization.update(organization_params)
      redirect_to organizations_path, notice: "Booking window updated successfully."
    else
      render :booking_window, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = current_user.organization
  end

  def organization_params
    params.require(:organization).permit(:booking_start_time, :booking_end_time)
  end
end
