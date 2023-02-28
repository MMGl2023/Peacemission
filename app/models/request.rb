class Request < ActiveRecord::Base
  has_many :people_requests
  has_many :people, :through=>:people_requests
  has_many :comments, -> { order("created_at") }, :as => :obj

  validates_presence_of :full_name, :address, :request_type, :details, :lost_full_name,
                :message => 'не должно быть пустым'

  validates_format_of :email, :with=>/\A(\s*|[\.\-\d\w]+@[\d\-\w\.]+)z/,
                :message => 'имеет неверный формат'

  # validates_numericality_of :anket_n # does not work. Why?

  @@cfg = APP_CONFIG['requests'] || {}

  def people=(ppls)
    curr = self.people
    to_del = curr - ppls
    to_add = (ppls - curr).uniq
    self.people.delete(*to_del)
    self.people.push(*to_add)
  end

  def type_short_string
    @type_short = (@@cfg['request_short_types']||{})[self.request_type]
  end

  def signature
    "№#{self.id} - #{self.type_short_string} - #{self.lost_full_name}"
  end
end

