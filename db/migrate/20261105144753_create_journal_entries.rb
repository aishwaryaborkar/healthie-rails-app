class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries, id: :uuid do |t|
      # Indexed in step 5 by a composite (patient_id, created_at, id) index,
      # which also serves plain patient_id lookups.
      t.references :patient, null: false, foreign_key: true, type: :uuid, index: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
