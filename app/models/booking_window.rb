class BookingWindow < ApplicationRecord
  belongs_to :organization

  validate :start_time_before_end_time

  private

  def start_time_before_end_time
    if start_time.present? && end_time.present? && start_time > end_time
      errors.add(:booking_start_time, "must be before or equal to booking end time")
    end
  end
end
