class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients, id: :uuid do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :patients, :email, unique: true
  end
end
