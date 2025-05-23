class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    if resource.organization.present?
      resource.organization.generate_and_attach_qr_code!
    end

    organization_path(resource.organization)
  end
end
