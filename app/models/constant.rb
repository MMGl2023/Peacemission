class Constant < ActiveRecord::Base
  class <<self
    def get(name)
      c = Constant.find_by_name(name)
      c and c.value
    end
    ## CACHING IS BAD IDEA  WHEN USING SEVERAL PROCESSES 
    # make_cached :get, :limit => 100, :no_wrap => true, :cache_if => lambda{|klass,arg,value| !value.nil?}

    def set(name, value)
      ## CACHING IS BAD IDEA  WHEN USING SEVERAL PROCESSES 
      # get_cache[name] = value 
      if c = Constant.find_by_name(name)
        c.value = value
        c.update_selected_attributes(:value)
        c
      else
        Constant.create(:name => name, :value => value)
      end
    end
  end

end
