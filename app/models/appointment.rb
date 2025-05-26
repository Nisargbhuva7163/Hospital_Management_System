class Appointment < ApplicationRecord
  belongs_to :organization
  validates :name, :age, :gender, :phone_number, :token_no, presence: true

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  before_create :set_default_status, if: :new_record?

  # default status for new appointments
  def set_default_status
    self.status ||= :pending
  end
end
