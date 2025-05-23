class OrganizationsController < ApplicationController

  def show
    @organization = Organization.find(params[:id])

    # Optional: Make sure the current user belongs to this org
    unless current_user.organization == @organization
      redirect_to root_path, alert: "Access denied."
    end
  end
end
