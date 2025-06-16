class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.string :name
      t.integer :age
      t.string :gender
      t.string :phone_number
      t.integer :token_no
      t.string :email
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
