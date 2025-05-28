class AddBookingWindowToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :booking_start_time, :time
    add_column :organizations, :booking_end_time, :time
  end
end
