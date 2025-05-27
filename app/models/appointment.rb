class Appointment < ApplicationRecord
  belongs_to :organization
  validates :name, :age, :gender, :phone_number, :token_no, presence: true

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  before_create :set_default_status, if: :new_record?

  after_create_commit :broadcast_current_token

  # default status for new appointments
  def set_default_status
    self.status ||= :pending
  end

  private

  def broadcast_current_token
    return unless pending?

    ActionCable.server.broadcast(
      "appointments_#{organization_id}",
      {
        token_no: token_no,
        name: name,
        phone_number: phone_number,
        age: age,
        gender: gender
      }
    )
  end
end
