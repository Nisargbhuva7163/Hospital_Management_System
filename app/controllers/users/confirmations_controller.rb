# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  # def create
  #   super
  # end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
  def show
    super do |resource|
      if resource.errors.empty?
        # Force logout after confirmation
        return redirect_to new_user_session_path, notice: "Your email has been confirmed. Please sign in."
      end
    end
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    new_user_session_path(resource_name) # This is typically: new_user_session_path
  end
end
