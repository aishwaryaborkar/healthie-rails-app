class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # UUIDv7: time-ordered, so new rows land at the end of the primary-key index.
  # Postgres 14 has no built-in v7 generator, so Ruby assigns it before INSERT.
  before_create { self.id ||= SecureRandom.uuid_v7 }
end
