class CreateBookingWindows < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_windows do |t|
      t.references :organization, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end
