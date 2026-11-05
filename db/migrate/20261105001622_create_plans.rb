class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :plans, :name, unique: true
  end
end
