class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show, :toggle_doctor_status ]
  def show
    unless @organization
      redirect_to root_path, alert: "Access denied."
      return
    end

    @current_token_appointment = @organization.appointments.where.not(status: "completed").order(created_at: :asc).first


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
      format.html { redirect_to organization_path, notice: "Doctor status updated." }
      format.js   # optional: for AJAX
    end
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
