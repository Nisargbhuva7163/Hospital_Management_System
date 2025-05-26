class AddStatusToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :status, :integer
  end
end
