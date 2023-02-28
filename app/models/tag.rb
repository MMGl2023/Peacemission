class Tag < ActiveRecord::Base
  has_many :tags_topics, :dependent => :destroy
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :topics, :through => :tags_topics


  def to_s
    name
  end

  class <<self
    def find_by_like_or_create_by_name(name)
      self.find(:first, :conditions => ['name LIKE ?', name]) || self.create(:name => name)
    end

    def find_by_search(search, options={})
      limit = options[:limit] || 10
      tags = Tag.find_all(
        :conditions => ["UPPER(name) LIKE UPPER(?)", "#{search}%"],
        :order => 'weight DESC',
        :limit => limit
      ) and (tags.size < limit) and
      tags << Tag.find_all(
        :conditions => ["UPPER(name) LIKE UPPER(?) and tag_id NOT IN (?)", "%#{search}", tags.map(&:id)],
        :order => 'weight DESC',
        :limit => limit
      )
      tags
    end
  end

end
