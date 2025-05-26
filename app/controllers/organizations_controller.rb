class OrganizationsController < ApplicationController

  def index
    @organization = current_user.organization

    unless @organization
      redirect_to root_path, alert: "Access denied."
      return
    end

    @current_token_appointment = @organization.appointments.where.not(status: "completed").order(created_at: :asc).first

    # Check if all appointments are completed
    if @organization.appointments.exists? && @organization.appointments.where.not(status: "completed").empty?
      @total_appointments_count = 0
    else
      @total_appointments_count = @organization.appointments.count
    end
  end

end
