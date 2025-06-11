class Appointment < ApplicationRecord
  belongs_to :organization
  validates :name, :age, :gender, :phone_number, :token_no, presence: true

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  before_create :set_default_status, if: :new_record?

  after_update_commit :broadcast_organization_update
  after_create_commit :broadcast_new_appointment

  # default status for new appointments



  def set_default_status
    self.status ||= :pending
  end

  private

  def broadcast_new_appointment
    broadcast_replace_to "organization_#{organization.id}_updates",
                        target: "appointments-table-body",
                        partial: "appointments/row",
                        locals: { appointment: self }
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
  end
end
