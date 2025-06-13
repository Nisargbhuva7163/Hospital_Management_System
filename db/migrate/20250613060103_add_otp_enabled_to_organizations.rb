class AddOtpEnabledToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :otp_enabled, :boolean, default: true
  end
end
