class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      # No separate patient_id index: the composite index below starts with
      # patient_id, so it already serves "all subscriptions for a patient".
      t.references :patient, null: false, foreign_key: true, type: :uuid, index: false
      t.references :provider, null: false, foreign_key: true, type: :uuid
      t.references :plan, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"

      t.timestamps

      t.check_constraint "status IN ('pending', 'active', 'paused', 'cancelled')",
                         name: "subscriptions_status_check"
    end
    # One subscription per patient–provider pair, ever.
    add_index :subscriptions, [:patient_id, :provider_id], unique: true
  end
end
