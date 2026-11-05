class Patient < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :providers, through: :subscriptions

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
