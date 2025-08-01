# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
    resource.build_organization
    respond_with resource
  end

  def create
    build_resource(sign_up_params)

    if resource.organization.present? && resource.save
      resource.add_role(:admin)  # Rolify assigns admin role
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        Rails.logger.debug "User errors: #{resource.errors.full_messages.inspect}"
        Rails.logger.debug "Organization errors: #{resource.organization.errors.full_messages.inspect}" if resource.organization.present?
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      Rails.logger.debug "User errors: #{resource.errors.full_messages.inspect}"
      Rails.logger.debug "Organization errors: #{resource.organization.errors.full_messages.inspect}" if resource.organization.present?
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      organization_attributes: [ :org_name, :phone_number, :address ]
    )
  end

  def account_update_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :current_password,
      organization_attributes: [ :id, :org_name, :phone_number, :address ]
    )
  end

  def after_update_path_for(resource)
    organization_path(current_user.organization) # 👈 Redirect to organization show
  end
end
