class OrganizationsController < ApplicationController
  def index
    @organization = current_user.organization

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
    @organization = current_user.organization

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
end
