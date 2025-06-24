class ErrorsController < ApplicationController
  def not_found
    if user_signed_in?
      redirect_to organization_path(current_user.organization), alert: "Page not found."
    end
  end
end
