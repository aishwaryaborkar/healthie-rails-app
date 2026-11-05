class JournalEntry < ApplicationRecord
  belongs_to :patient

  validates :body, presence: true

  # id breaks ties when two entries share a timestamp.
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
end
