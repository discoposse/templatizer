class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_digest&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 2.days do
    email_address
  end

  generates_token_for :magic_link, expires_in: 5.minutes do
    password_digest&.last(10)
  end

  scope :email_confirmed, -> { where.not(email_confirmed_at: nil) }
  scope :email_unconfirmed, -> { where(email_confirmed_at: nil) }

  def admin?
    !!admin
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!
    update_column(:email_confirmed_at, Time.current) unless email_confirmed?
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email_address.to_s.split("@").first.to_s.humanize
  end

  def profile_complete?
    first_name.present? && last_name.present?
  end

  def send_confirmation_email
    ApplicationMailer.deliver_auth_message(EmailConfirmationsMailer.confirmation_email(self))
  end

  def send_password_reset_email
    ApplicationMailer.deliver_auth_message(PasswordResetsMailer.reset_email(self))
  end

  def send_magic_link_email
    ApplicationMailer.deliver_auth_message(MagicLinksMailer.sign_in_email(self))
  end
end
