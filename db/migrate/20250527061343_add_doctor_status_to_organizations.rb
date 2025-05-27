class AddDoctorStatusToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :doctor_status, :string, default: "checked-out"
  end
end
