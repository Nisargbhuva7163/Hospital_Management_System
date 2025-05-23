# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(resource)
    organization_path(resource.organization)
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def send_otp
    organization = Organization.find_by(phone_number: params[:phone_number])

    if organization.present?
      phone_number = formatted_phone_number(organization.phone_number)
      if SmsService.send_otp(phone_number)
        render json: { success: true, phone_number: phone_number }, status: :ok
      else
        render json: { success: false, error: "❌ Failed to send OTP. Please try again." }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "❌ Phone number not found." }, status: :not_found
    end
  end

  def verify_otp
    organization = Organization.find_by(phone_number: params[:phone_number])

    if organization.present?
      phone_number = formatted_phone_number(organization.phone_number)

      if SmsService.verify_otp(phone_number, params[:otp_code])
        user = User.find_by(organization_id: organization.id) # 🔁 find the user belonging to this org

        if user.present?
          sign_in(:user, user)
          render json: {
            success: true,
            redirect_path: organization_path(user.organization)
          }, status: :ok
        else
          render json: { success: false, error: "❌ No user associated with this organization." }, status: :not_found
        end
      else
        render json: { success: false, error: "❌ Invalid OTP or OTP expired." }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "❌ Phone number not found." }, status: :not_found
    end
  end

  def resend_otp
    organization = Organization.find_by(phone_number: params[:phone_number])

    if organization.present?
      phone_number = formatted_phone_number(organization.phone_number)
      if SmsService.send_otp(phone_number)
        render json: { success: true, message: "✅ OTP resent successfully." }, status: :ok
      else
        render json: { success: false, error: "❌ Failed to resend OTP." }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "❌ Phone number not found." }, status: :not_found
    end
  end

  private

  def formatted_phone_number(phone_number)
    phone_number.start_with?("+91") ? phone_number : "+91#{phone_number}"
  end
end
