class RecentPerson < ActiveRecord::Base
  has_many :comments, -> { order("created_at") }, :as => :obj

  before_save :fix_full_name

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
