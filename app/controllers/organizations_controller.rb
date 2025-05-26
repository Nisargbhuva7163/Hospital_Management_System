class OrganizationsController < ApplicationController

  def index
    @organization = current_user.organization

    unless @organization
      redirect_to root_path, alert: "Access denied."
      return
    end

    @current_token_appointment = @organization.appointments.order(created_at: :asc).first
    @total_appointments_count = @organization.appointments.count
  end

end
