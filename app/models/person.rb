class Person < ActiveRecord::Base
  has_many :comments, -> { order("created_at") }, as: :obj
  belongs_to :lost, optional: true
  has_many :people_requests
  has_many :requests, through: :people_requests

  before_save :fix_full_name

  def requests=(reqs)
    curr = self.request_ids.to_a
    to_del = curr - reqs
    to_add = (reqs - curr).uniq
    self.request_ids.delete(*to_del) if to_del.present?
    self.request_ids.push(*to_add) if to_add.present?
  end

  def fix_full_name
    self.full_name = (self.full_name || '').gsub(/\s+/, ' ').gsub(/^\s*|\s*$/, '')
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
