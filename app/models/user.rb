require 'digest/sha1'

class User < ActiveRecord::Base
  include AASM
  has_many :roles_users, dependent: :destroy
  has_many :roles, through: :roles_users

  belongs_to :image, class_name: 'Fitem', foreign_key: 'image_id', optional: true

  composed_of :tz, class_name: 'TZInfo::Timezone', mapping: %w( time_zone time_zone )

  # Virtual attribute for the unencrypted password
  attr_accessor :password, :current_password

  validates_presence_of :login, :email, message: 'не должно быть пустым'

  validates_presence_of :password, if: :password_required?, message: 'не должно быть пустым'

  validates_presence_of :password_confirmation, if: :password_required?,
                        message: 'не должно быть пустым'

  validates_length_of :password, within: 4..20, if: :password_required?

  validates_confirmation_of :password, if: :password_required?,
                            message: 'пароль должен совпадать с его подтверждением'

  validates_length_of :login, within: 3..40

  validates_format_of :login, with: /\A\w[\d\w\.\-]{2,31}\z/,
                      message: "должно состоять из букв, цифр и знаков '_', '.', '-', начинаться на букву, иметь длину более 2 символов и менее 33 символов"

  validates_length_of :email, within: 5..100

  validates_format_of :email, with: /(^([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})$)|(^$)/i,
                      message: "должно иметь правильный формат"

  validates_uniqueness_of :login, :email, case_sensitive: false,
                          message: "пользователь с таким логином/email-ом  уже существует"

  before_save :check_password_strength
  before_save :encrypt_password

  attr_accessor :invitation_code, :invitation

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # attr_accessor :login, :email, :password, :password_confirmation,
  #               :full_name, :country, :time_zone, :invitation_code, :info

  class << self
    make_cached :get, method: :find_by_id, recache_after: 1.hour, limit: 20
  end

  aasm.attribute_name :state

  aasm do
    state :pending, initial: true
    state :passive
    state :pending, enter: :make_activation_code
    state :active, enter: :do_activate
    state :suspended
    state :deleted, enter: :do_delete

    event :register do
      transitions from: :passive, to: :pending, guard: Proc.new { |u| !(u.crypted_password.blank? && u.password.blank?) }
    end

    event :activate do
      transitions from: :pending, to: :active
    end

    event :suspend do
      transitions from: [:passive, :pending, :active], to: :suspended
    end

    event :delete do
      transitions from: [:passive, :pending, :active, :suspended], to: :deleted
    end

    event :unsuspend do
      transitions from: :suspended, to: :active, guard: Proc.new { |u| !u.activated_at.blank? }
      transitions from: :suspended, to: :pending, guard: Proc.new { |u| !u.activation_code.blank? }
      transitions from: :suspended, to: :passive
    end
  end

  def self.generate_password
    password = ''
    chars = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!@$%^&()+=|\\<>,"
    (rand(4) + 5).times { password += chars[rand(chars.length - 1), 1] }
    password
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    # u = find_in_state :first, :active, conditions: { login: login } # need to get the salt
    u = self.active.find_by(login: login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token = encrypt("#{email}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token = nil
    save(validate: false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  #used in user_observer
  def recently_forgot_password?
    @forgotten_password
  end

  def recently_reset_password?
    @reset_password
  end

  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end

  def self.find_for_forget(email)
    find :first, conditions: ['email = ? and activated_at IS NOT NULL', email]
  end

  def reset_password
    # First update the password_reset_code before setting the
    # reset_password flag to avoid duplicate email notifications.
    update_attribute(:password_reset_code, nil)
    @reset_password = true
  end

  # For admin ruby console
  #def password=(p)
  #  @password = p
  #  encrypt_password
  #  @password = nil
  #end

  def self.strong_password?(p)
    #(p.length > 4) &&
    #(p =~ /[^a-z]/i) &&
    #(p =~ /\A[a-z0-9!@#$\%\^&*?\\\[\]\(\)_\+=\-]{5,9}\z/i)i
    true
  end

  def admin?
    has_role[:admin]
  end

  # returns and caches hash { role (symbolized name) => true/nil }
  def has_role
    @has_role ||= roles.inject({}) { |h, r|
      h[r.role.to_sym] = true; h
    }
  end

  # returns and caches hash { permission (symbolized name) => true/nil }
  def has_permission
    @has_permission ||= admin? ? Hash.new { |h, k|
      k != :viewer # :viewer is special anti-permission
    } : roles.map(&:permissions).flatten.uniq.inject({}) { |h, p|
      h[p.permission.to_sym] = true; h
    }
  end

  # for ActiveScaffold user field
  def to_label
    (self.login || '') + ':' + (self.name || '')
  end

  def image_url
    if self.image
      self.image.url
    else
      '/images/nopicture.png'
    end
  end

  def days_until_birthday
    today = Date.today
    b = self.birth_date
    b1 = Date.civil(today.year, b.month, b.day)
    b2 = Date.civil(today.year + 1, b.month, b.day)
    days = b1 - today
    days = b2 - today if days < 0
    days
  end

  if INVITATION_NEEDED
    after_create :mark_invitation_as_used

    def mark_invitation_as_used
      if @invitation
        @invitation.used_by_id = self.id
        @invitation.used_at = Time.now
        @invitation.update_selected_attributes(:used_by_id, :used_at)
      end
    end

    validates_each :invitation_code, on: :create do |record, attr, value|
      if record.invitation_code.nil?
        record.errors.add attr, 'требуется приглашение'
      elsif record.invitation = Invitation.find_by_code(record.invitation_code)
        if record.invitation.used_by
          record.errors.add attr, 'приглашение уже использовано'
        elsif !record.invitation.expired_at.blank? &&
          record.invitation.expired_at < Time.now
          record.errors.add attr, 'срок активации приглашения истек'
        else
          # everything is ok
          # record.id is not initialized here yet
          # see mark_invitation
        end
      else
        record.errors.add attr, "недействителен"
      end
    end
  end

  protected

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if self.salt.blank?
    self.crypted_password = encrypt(password)
  end

  def check_password_strength
    return if password.blank?
    self.errors.add :password, "Слабый пароль" unless self.class.strong_password?(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
  end

  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
  end

  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end
end

