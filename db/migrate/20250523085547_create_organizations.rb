class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :org_name
      t.string :phone_number
      t.text :address

      t.timestamps
    end
  end
end
