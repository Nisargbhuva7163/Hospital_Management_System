class Appointment < ApplicationRecord
  belongs_to :organization
  validates :name, :age, :gender, :phone_number, :token_no, presence: true

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  before_create :set_default_status, if: :new_record?

  after_update_commit :broadcast_organization_update

  # default status for new appointments



  def set_default_status
    self.status ||= :pending
  end

  private

  def broadcast_organization_update
    broadcast_replace_to "appointment_#{id}_updates",
                         target: "appointment-status-message",
                         partial: "appointments/status_message",
                         locals: { appointment: self }

    current_token = organization.appointments
                                .where.not(status: "completed")
                                .order(created_at: :asc)
                                .first

    # Get total appointments count
    total_appointments_count = organization.appointments.count

    # Broadcast current token box update
    Turbo::StreamsChannel.broadcast_update_to(
      "organization_#{organization.id}_updates",
      target: "current-token-display",
      partial: "appointments/current_token",
      locals: { current_token_appointment: current_token }
    )

    # Broadcast total appointments count box update
    Turbo::StreamsChannel.broadcast_update_to(
      "organization_#{organization.id}_updates",
      target: "total-appointments-count",
      partial: "appointments/total_appointments_count",
      locals: { total_appointments_count: total_appointments_count }
    )

  end
end
