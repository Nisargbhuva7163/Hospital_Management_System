class AppointmentsController < ApplicationController
  before_action :set_organization
  before_action :set_appointment, only: [ :preview, :complete, :skip, :update ]
  before_action :authenticate_user!, except: [ :new, :create, :send_otp, :verify_otp, :preview ]
  skip_before_action :verify_authenticity_token, only: [ :send_otp, :verify_otp ]

  def index
      @appointments = @organization.appointments.where(created_at: Date.today.all_day).order(created_at: :asc)
  end

  def new
    @appointment = @organization.appointments.new
    @booking_windows = @organization.booking_windows.order(:start_time)
    @booking_closed = !@organization.within_booking_window?
    puts @booking_closed
  end

  def preview
    @current_token_appointment = @organization.appointments
                                              .where.not(status: "completed")
                                              .order(created_at: :asc)
                                              .first
  end

  def create
    @organization = Organization.includes(:booking_windows).find(params[:organization_id])

    unless @organization.within_booking_window?
      render :new and return
    end

    @appointment = @organization.appointments.new(appointment_params)
    Rails.logger.debug "Appointment params: #{appointment_params.inspect}"

    if params[:confirm] == "true"
      # Save appointment for OTP-disabled case
      last_token_no = @organization.appointments.maximum(:token_no) || 0
      @appointment.token_no = last_token_no + 1

      if @appointment.save
        Rails.logger.debug "Appointment saved: #{@appointment.inspect}"
        render json: {
          success: true,
          redirect_path: preview_organization_appointment_path(@organization, @appointment)
        }, status: :ok
      else
        Rails.logger.error "Failed to save appointment: #{@appointment.errors.full_messages.join(', ')}"
        render json: {
          success: false,
          errors: @appointment.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      # Validate and return confirm modal
      if @appointment.valid?
        html = render_to_string(partial: "confirm", formats: [ :html ], locals: { appointment: @appointment, organization: @organization })
        render json: { success: true, html: html }
      else
        Rails.logger.error "Validation failed: #{@appointment.errors.full_messages.join(', ')}"
        render json: { success: false, errors: @appointment.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def send_otp
    phone = format_phone_number(params.dig(:appointment, :phone_number))

    if phone.present? && SmsService.send_otp(phone)
      render json: { success: true, message: "OTP sent successfully to #{phone}" }, status: :ok
    else
      render json: { success: false, error: "Failed to send OTP. Please check the phone number." }, status: :unprocessable_entity
    end
  end

  def verify_otp
    phone = format_phone_number(params[:phone_number])
    otp_code = params[:otp_code]

    if SmsService.verify_otp(phone, otp_code)
      appointment_params = params.require(:appointment).permit(:name, :age, :gender, :phone_number, :email)
      last_token_no = @organization.appointments.maximum(:token_no) || 0
      new_token_no = last_token_no + 1

      @appointment = @organization.appointments.new(appointment_params.merge(token_no: new_token_no))

      if @appointment.save
        render json: {
          success: true,
          redirect_path: preview_organization_appointment_path(@organization, @appointment),
          token_no: new_token_no
        }, status: :ok
      else
        Rails.logger.error "Failed to save appointment in verify_otp: #{@appointment.errors.full_messages.join(', ')}"
        render json: { success: false, error: @appointment.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "Invalid or expired OTP." }, status: :unprocessable_entity
    end
  end

  def update
    if @appointment.update(status_params)
      redirect_to organization_appointments_path(@organization), notice: "Appointment updated successfully."
    else
      redirect_to organization_appointments_path(@organization), alert: "Failed to update appointments."
    end
  end

  def complete
    if @appointment.update(status: "completed")
      redirect_to organization_appointments_path(@organization), notice: "Appointment marked as completed."
    else
      redirect_to organization_appointments_path(@organization), alert: "Failed to update appointments."
    end
  end

  def skip
    if @appointment.update(status: "skipped")
      redirect_to organization_appointments_path(@organization), notice: "Appointment marked as skipped."
    else
      redirect_to organization_appointments_path(@organization), alert: "Failed to update appointments."
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_appointment
    @appointment = @organization.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:name, :age, :gender, :phone_number, :email)
  end

  def status_params
    params.require(:appointment).permit(:status)
  end

  def format_phone_number(phone)
    return "" if phone.blank?
    phone.start_with?("+91") ? phone : "+91#{phone}"
  end
end
