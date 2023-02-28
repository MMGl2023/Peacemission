require 'mixin_class_methods'

module BaseExt
  mixin_class_methods

  def update_selected_attributes(*attributes)
    attributes = attributes.first if attributes.first.is_a?(Enumerable) && attributes.size == 1
    if attributes.is_a?(Hash)
      attributes.each do |k,v|
        self[k] = v
      end
      attributes = attributes.keys
    end

    self.class.update_all(
      attributes.map{|a|
        a = a.to_s
        if self.class.serialized_attributes[a]
          a + "='" + self[a].to_yaml.gsub("\n",'\n').gsub("'"){"\\'"} + "'"
        else
          self.class.send(:sanitize_sql_hash_for_assignment, a => self[a])
        end
      }.join(', '),
      {:id => self.id}
    )
  end


  define_class_methods do
    def max_id
      x = self.find_by_sql("SELECT MAX(id) AS id FROM #{self.table_name}").first
      if x
        x.id||0
      else
        0
      end
    end

    def each
      (1..self.max_id+10).each do |i|
        o = self.find_by_id(i)
        if o
          yield o
        end
      end
      self
    end

    def random(field = 'id')
      count = self.count
      return nil if count == 0
      self.find(:first, :limit=>2, :conditions=>["`#{field}` > ?", rand(max_id) ])
    end

    def random_array(n, field = 'id')
      return [] if n == 0
      count = self.count
      return self.find(:all) if count <= n
      field = field.to_s
      max_id = self.max_id
      res = Set.new
      while res.size <= n
        lim = 1+ rand(3)
        res += self.find(:all, :limit=>lim, :conditions=>["`#{field}` > ?", rand(max_id) ])
      end
      res.to_a.last_n(n)
    end

    def id_and_object(t)
      if t.is_a?(self)
        [t.id, t]
      else
        [t.to_i, self.find_by_id(t.to_i)]
      end
    end
  end
end

module ActiveRecord; end
class ActiveRecord::Base
  include BaseExt
  # make public method
  def self.san_sql(cnd) 
    sanitize_sql(cnd) 
  end
  
  def d_id
    @d_id ||= 'd_' + self.class.to_s.underscore + '_' + self.id.to_s
  end
  
  def to_i
    self.id
  end
end

def sanitize_sql(cnd)
  ActiveRecord::Base.san_sql(cnd)
end

