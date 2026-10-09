class Session < ApplicationRecord
  belongs_to :user

  def expired?
    created_at < 30.days.ago
  end
end
