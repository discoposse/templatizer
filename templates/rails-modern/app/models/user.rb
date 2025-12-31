class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }
  validates :first_name, presence: true, on: :update_profile
  validates :last_name, presence: true, on: :update_profile

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_digest&.last(10)
  end

  generates_token_for :email_verification, expires_in: 2.days do
    email_address_before_last_save
  end

  generates_token_for :magic_link, expires_in: 5.minutes

  before_validation :normalize_email

  # Scopes
  scope :email_confirmed, -> { where.not(email_confirmed_at: nil) }
  scope :email_unconfirmed, -> { where(email_confirmed_at: nil) }

  # Compatibility method for password reset tokens
  def self.find_by_password_reset_token!(token)
    find_by_token_for(:password_reset, token) || raise(ActiveRecord::RecordNotFound)
  end

  def admin?
    admin
  end

  def subscriber?
    return false unless has_attribute?(:subscriber)
    self[:subscriber] || false
  end

  def profile_complete?
    first_name.present? && last_name.present?
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!
    update_column(:email_confirmed_at, Time.current) unless email_confirmed?
  end

  def send_confirmation_email
    # Use deliver_now in development for immediate email delivery
    # deliver_later uses background jobs which may not be running
    if Rails.env.development?
      EmailConfirmationsMailer.confirmation_email(self).deliver_now
    else
      EmailConfirmationsMailer.confirmation_email(self).deliver_later
    end
  end

  def full_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}".strip
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      email_address.split("@").first.humanize
    end
  end

  private

  def normalize_email
    self.email_address = email_address.downcase.strip if email_address.present?
  end
end
