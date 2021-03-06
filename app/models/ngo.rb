class Ngo < ApplicationRecord
  acts_as_paranoid
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable, :validatable

  enum locale: { de: 0, en: 1 }

  scope :pending,   -> { where(admin_confirmed_at: nil) }
  scope :confirmed, -> { where.not(admin_confirmed_at: nil) }

  has_many :events, dependent: :restrict_with_error
  has_one :contact, dependent: :destroy, inverse_of: :ngo
  accepts_nested_attributes_for :contact, reject_if: :all_blank

  validates :name, presence: true
  validates_presence_of :contact
  validates :terms_and_conditions, acceptance: true

  after_commit :request_admin_confirmation, on: :create

  def confirm!
    if !confirmed? && update(admin_confirmed_at: Time.now)
      send_admin_confirmation
    end
  end

  def state
    %w(deleted confirmed).each { |state| return state if send("#{state}?") }
    'pending'
  end

  def self.send_reset_password_instructions(attributes={})
   recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
   if !recoverable.confirmed?
     recoverable.errors[:base] << I18n.t('devise.failure.not_admin_confirmed')
   elsif recoverable.persisted?
     recoverable.send_reset_password_instructions
   end
   recoverable
 end

  # overwrite devise to require admin confirmation too
  def active_for_authentication?
    super && confirmed?
  end

  # custom message if requires admin confirmation
  def inactive_message
    confirmed? ? :not_admin_confirmed : super
  end

  def new_event
    t = Time.now + 15.minutes
    starts = t - t.sec - t.min%15*60
    ends = starts +  2.hours
    shifts_attr = [{ volunteers_needed: 1, starts_at: starts, ends_at: ends }]
    events.build shifts_attributes: shifts_attr
  end

  private

  def confirmed?
    admin_confirmed_at.present?
  end

  def request_admin_confirmation
    AdminMailer.new_ngo(self).deliver_later
  end

  def send_admin_confirmation
    NgoMailer.admin_confirmed(self).deliver_later
  end
end
