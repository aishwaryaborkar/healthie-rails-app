class Plan < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
