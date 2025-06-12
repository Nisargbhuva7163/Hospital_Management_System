class AppointmentsController < ApplicationController
  before_action :set_organization
  before_action :set_appointment, only: [ :preview, :complete, :skip, :update ]
  before_action :authenticate_user!, except: [:new, :create, :send_otp, :verify_otp, :preview]
  skip_before_action :verify_authenticity_token, only: [ :send_otp, :verify_otp ]


  def index
    @appointments = @organization.appointments.order(created_at: :asc)
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
    if @organization.within_booking_window?
      redirect_to new_organization_appointment_path(@organization), alert: "Please use OTP verification to book an appointments."
    else
      render :new
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
      appointment_params = params.require(:appointment).permit(:name, :age, :gender, :phone_number)
      last_token_no = @organization.appointments.maximum(:token_no) || 0
      new_token_no = last_token_no + 1

      @appointment = @organization.appointments.new(appointment_params.merge(token_no: new_token_no))

      if @appointment.save
        turbo_stream_update_organization(@organization)

        render json: {
          success: true,
          redirect_path: preview_organization_appointment_path(@organization, @appointment),
          token_no: new_token_no
        }, status: :ok
      else
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
      turbo_stream_update_organization(@organization)
      redirect_to organization_appointments_path(@organization), notice: "Appointment marked as completed."
    else
      redirect_to organization_appointments_path(@organization), alert: "Failed to update appointments."
    end
  end

  def skip
    if @appointment.update(status: "skipped")
      turbo_stream_update_organization(@organization)
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
    params.require(:appointment).permit(:name, :age, :gender, :phone_number)
  end

  def status_params
    params.require(:appointment).permit(:status)
  end

  def format_phone_number(phone)
    return "" if phone.blank?
    phone.start_with?("+91") ? phone : "+91#{phone}"
  end

  def turbo_stream_update_organization(organization)
    current_token = organization.appointments.where(status: "pending").order(:token_no).first
    total_count = organization.appointments.count
    appointments = organization.appointments.order(created_at: :asc)
    last_token = organization.appointments.where(status: "pending").order(updated_at: :desc).first



    # You can set instance variables or broadcast partials directly
    Turbo::StreamsChannel.broadcast_replace_to(
      "organization_#{organization.id}_updates",
      target: "current-token-display",
      partial: "organizations/current_token",
      locals: { current_token: current_token }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "organization_#{organization.id}_updates",
      target: "total-appointments-count",
      partial: "organizations/total_count",
      locals: { total_count: total_count }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "organization_#{organization.id}_updates",
      target: "appointments-list",
      partial: "appointments/list",
      locals: { appointments: appointments, organization: organization }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "organization_#{organization.id}_updates",
      target: "last-token-display",
      partial: "organizations/last_token",
      locals: { last_token: last_token }
    )
  end
end
