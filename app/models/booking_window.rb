class BookingWindow < ApplicationRecord
  belongs_to :organization

  validate :start_time_before_end_time

  private

  def start_time_before_end_time
    if booking_start_time.present? && booking_end_time.present? && booking_start_time > booking_end_time
      errors.add(:booking_start_time, "must be before or equal to booking end time")
    end
  end
end
