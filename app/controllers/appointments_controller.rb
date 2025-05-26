class AppointmentsController < ApplicationController
  before_action :set_organization
  skip_before_action :verify_authenticity_token, only: [:send_otp, :verify_otp]

  def index
    @appointments = @organization.appointments.order(created_at: :asc)
  end

  def new
    @appointment = @organization.appointments.new
  end

  # Only handles direct form submissions (NOT used in OTP flow)
  def create
    redirect_to new_organization_appointment_path(@organization), alert: "Please use OTP verification to book an appointment."
  end

  # POST /organizations/:organization_id/appointments/send_otp
  def send_otp
    phone = format_phone_number(params.dig(:appointment, :phone_number))

    if phone.present? && SmsService.send_otp(phone)
      render json: { success: true, message: "OTP sent successfully to #{phone}" }, status: :ok
    else
      render json: { success: false, error: "Failed to send OTP. Please check the phone number." }, status: :unprocessable_entity
    end
  end

  # POST /organizations/:organization_id/appointments/verify_otp
  def verify_otp
    phone = format_phone_number(params[:phone_number])
    otp_code = params[:otp_code]

    if SmsService1.verify_otp(phone, otp_code)
      # Permit data sent along with OTP
      appointment_params = params.require(:appointment).permit(:name, :age, :gender, :phone_number)

      last_token_no = @organization.appointments.maximum(:token_no) || 0
      new_token_no = last_token_no + 1

      @appointment = @organization.appointments.new(appointment_params.merge(token_no: new_token_no))

      if @appointment.save
        render json: {
          success: true,
          redirect_path: organization_appointment_path(@organization, @appointment),
          token_no: new_token_no
        }, status: :ok
      else
        render json: { success: false, error: @appointment.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "Invalid or expired OTP." }, status: :unprocessable_entity
    end
  end

  def show
    @appointment = @organization.appointments.find(params[:id])
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def appointment_params
    params.require(:appointment).permit(:name, :age, :gender, :phone_number)
  end

  def format_phone_number(phone)
    return "" if phone.blank?
    phone.start_with?("+91") ? phone : "+91#{phone}"
  end
end
