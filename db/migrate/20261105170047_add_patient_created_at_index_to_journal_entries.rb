class AddPatientCreatedAtIndexToJournalEntries < ActiveRecord::Migration[8.1]
  def change
    # Filter by patient, then sort by time. id breaks ties for the feed cursor.
    add_index :journal_entries, [:patient_id, :created_at, :id]
  end
end
