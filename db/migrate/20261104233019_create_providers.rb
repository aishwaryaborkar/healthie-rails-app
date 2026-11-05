class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers, id: :uuid do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :providers, :email, unique: true
  end
end
