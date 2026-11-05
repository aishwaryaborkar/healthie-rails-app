class Provider < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :patients, through: :subscriptions

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Patients with an active subscription to this provider.
  def active_patients
    patients.merge(Subscription.active)
  end

  # Journal entries from all of this provider's active patients, newest first.
  # One query: journal_entries -> patients -> subscriptions.
  def journal_feed
    JournalEntry.joins(patient: :subscriptions)
                .merge(Subscription.active.where(provider: self))
                .newest_first
  end
end
