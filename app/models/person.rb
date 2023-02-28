class Person < ActiveRecord::Base
  has_many :comments, :as => :obj, :order => "created_at DESC"
  belongs_to :lost
  has_many :people_requests
  has_many :requests, :through => :people_requests

  before_save :fix_full_name

  def requests=(reqs)
    curr = self.requests.to_a
    to_del = curr - reqs
    to_add = (reqs - curr).uniq
    self.requests.delete(*to_del)
    self.requests.push(*to_add)
  end

  def fix_full_name
    self.full_name = (self.full_name||'').gsub(/\s+/, ' ').gsub(/^\s*|\s*$/, '')
  end

  def signature
    "№#{self.id} - #{self.full_name}"
  end

  def disappear_address
    (!disappear_region.blank? && !disappear_location.index(disappear_region) ?
      "#{disappear_region}, #{disappear_location}" :
      disappear_location
    )
  end
end
