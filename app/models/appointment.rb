class Appointment < ApplicationRecord
  belongs_to :organization
  validates :name, :age, :gender, :phone_number, :token_no, presence: true
end
