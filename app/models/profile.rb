class Profile < ActiveRecord::Base
  belongs_to :user

  validates :gender, inclusion: {in: %w(Male Female Unknown), message: "%{value} is not a valid gender"},
            allow_nil: false
end
