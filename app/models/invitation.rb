class Invitation < ActiveRecord::Base
 
  unless defined? INVITATION_EXPIRE_AFTER 
    INVITATION_EXPIRE_AFTER = 2.weeks
  end

  belongs_to :created_by, :class_name=>'User', :foreign_key=>:created_by_id

  belongs_to :used_by, :class_name=>'User', :foreign_key=>:used_by_id


  validates_format_of :email, 
    :with=>/^([^@\s]+|"[^@]+")@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i 

  validates_presence_of :name

  before_create :set_expired_at 

  before_create :make_code
  
  def make_code
    self.code = Digest::SHA1.hexdigest( (1..5).map{rand.to_s}.join + 'saltsydtsydt' + email.to_s )
  end

  def set_expired_at
    self.expired_at = (self.created_at ||= Time.now.utc) + INVITATION_EXPIRE_AFTER
  end

  def send_inv
    return <<END
<form action="/invitations/#{self.id}/send_env" method="post">
  <input type="submit" value="Send">
</form>
END
  end

  def send_inv=(any)
  end
end

