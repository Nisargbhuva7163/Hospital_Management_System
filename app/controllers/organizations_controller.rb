class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show, :edit, :update, :toggle_doctor_status ]
  def show
    unless @organization
      redirect_to root_path, alert: "Access denied."
      return
    end

    @current_token_appointment = @organization.appointments.where.not(status: "completed").order(created_at: :asc).first


      @total_appointments_count = @organization.appointments.count


    @last_token_appointment = @organization.appointments.order(token_no: :desc).first
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if user_params[:password].present?
      unless @user.valid_password?(params[:user][:current_password])
        flash.now[:alert] = "Current password is incorrect."
        render :edit and return
      end
    end

    if @organization.update(organization_params) && @user.update(user_params.except(:current_password))
      redirect_to organization_path, notice: "Organization and user details updated successfully."
    else
      flash.now[:alert] = "There was a problem updating the details."
      render :edit
    end
  end


  def toggle_doctor_status
    if @organization.checked_in?
      @organization.update(doctor_status: "checked_out")
    else
      @organization.update(doctor_status: "checked_in")
    end


    Turbo::StreamsChannel.broadcast_replace_to(
      "organization_#{@organization.id}_updates",
      target: "doctor-status-nav",
      partial: "organizations/doctor_status_nav",
      locals: { organization: @organization }
    )

    respond_to do |format|
      format.html { redirect_to organization_path, notice: "Doctor status updated." }
      format.js   # optional: for AJAX
    end
  end

  private

  def set_organization
    @organization = current_user.organization
  end

  def organization_params
    params.require(:organization).permit(:org_name, :phone_number, :address)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password)
  end
end
