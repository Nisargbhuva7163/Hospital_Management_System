class Appointment < ApplicationRecord
  belongs_to :organization

  validates :name, presence: true, format: { with: /\A\S+\z/, message: "must not contain spaces" }
  validates :age, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 110 }
  validates :gender, presence: true
  validates :phone_number, format: { with: /\A\d{10}\z/, message: "must be exactly 10 digits" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  before_create :set_default_status, if: :new_record?

  after_create_commit :broadcast_new_appointment
  after_update_commit :broadcast_organization_update

  # default status for new appointments


  def set_default_status
    self.status ||= :pending
  end

  private

  def broadcast_new_appointment
    broadcast_append_to "organization_#{organization.id}_updates",
                        target: "appointments-table-body",
                        partial: "appointments/row",
                        locals: { appointment: self }


    broadcast_common_organization_updates
  end
  def broadcast_organization_update
    broadcast_replace_to "appointment_#{id}_updates",
                         target: "appointments-status-message",
                         partial: "appointments/status_message",
                         locals: { appointment: self }


    broadcast_replace_to "organization_#{organization.id}_updates",
                         target: "appointment_row_#{id}",
                         partial: "appointments/row",
                         locals: { appointment: self }


    broadcast_common_organization_updates
  end

  def broadcast_common_organization_updates
    current_token = organization.appointments.where(status: "pending").order(:created_at).first
    total_count = organization.appointments.count
    appointments = organization.appointments.order(created_at: :asc)
    last_token = organization.appointments.order(created_at: :desc).first

    broadcast_replace_to "organization_#{organization.id}_updates",
                         target: "current-token-display",
                         partial: "organizations/current_token",
                         locals: { current_token: current_token }

    # Update last token display
    broadcast_replace_to "organization_#{organization.id}_updates",
                         target: "last-token-display",
                         partial: "organizations/last_token",
                         locals: { last_token: last_token }

    # Update total appointment count
    broadcast_replace_to "organization_#{organization.id}_updates",
                         target: "total-appointments-count",
                         partial: "organizations/total_count",
                         locals: { total_count: total_count }

    # Update appointment list (optional, if needed)
    broadcast_replace_to "organization_#{organization.id}_updates",
                         target: "appointments-list",
                         partial: "appointments/list",
                         locals: { appointments: appointments, organization: organization }
  end
end
