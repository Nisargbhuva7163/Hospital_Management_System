class BookingWindow < ApplicationRecord
  belongs_to :organization

  validate :start_time_before_end_time

  validate :booking_window_does_not_overlap


  private

  def start_time_before_end_time
    if start_time.present? && end_time.present? && start_time > end_time
      errors.add(:booking_start_time, "must be before or equal to booking end time")
    end
  end

  def booking_window_does_not_overlap
    return if start_time.blank? || end_time.blank?

    overlapping_windows = BookingWindow
                            .where(organization_id: organization_id)
                            .where.not(id: id) # exclude self in case of update
                            .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping_windows.exists?
      errors.add(:base, "Booking window overlaps with an existing window")
    end
  end
end
