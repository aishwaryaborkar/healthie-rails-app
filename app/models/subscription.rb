class Subscription < ApplicationRecord
  belongs_to :patient
  belongs_to :provider
  belongs_to :plan

  enum :status, {
    pending: "pending",
    active: "active",
    paused: "paused",
    cancelled: "cancelled"
  }, validate: true

  validates :provider_id, uniqueness: {
    scope: :patient_id,
    message: "already has a subscription with this patient"
  }
end
