# :main: HashHeap
# :stopdoc:

class IndexedValueArray < Array #:nodoc:
  def []=(i,v)
    unless v.respond_to?(:idx)
      class <<v
        attr_accessor :idx
      end
    end 
    v.idx = i
    super(i,v)
  end
end

# HeapItem encapsulates pair [k, v].
# Subclass of HeapItem should be passed to HashHeap#new.
# This class should have operator +<=+ that defines which 
# element will be extracted first -- the greatest one.
class HeapItem
  attr_accessor :k,:v,:idx
  def initialize(k,v,idx=0) #:nodoc:
    @k,@v,@idx = k,v,idx
  end
  def <=(x) # by defalt priority queue extracts pair with max value
    self.v <= x.v 
  end
end

class HeapItemValueMaxKeyMin < HeapItem #:nodoc: all
  def <=(x)
    self.v < x.v || (self.v == x.v && self.k >= x.k)
  end
end

class HeapItemKeyMin < HeapItem #:nodoc: all
  def <=(x)
    self.k >= x.k
  end
end

class HeapItemValueMin < HeapItem #:nodoc: all
  def <=(x)
    (self.v||0) >= (x.v||0)
  end
end

# HashHeap provides both Hash (partially) and priority queue API.
# It stores pairs [k,v] and provides methods HashHeap#[],
# HashHeap#[]=, HashHeap#clear equivalent to corresponding Hash methods.
#
# Besides HashHeap has method #extract, that returns and removes pair +[k,v]+
# which maximal with respect to operator HeapItem#<=.
# Subclass of HeapItem should be given to HashHeap#new method.
#  
#  products = HashHeap.new(nil, HeapItemValueMin)
#  products[:computer] = 600
#  products[:pensil] = 1
#  products[:scarf] = 10
#  products.extract # => [:pensil, 1]
class HashHeap 
  attr_accessor :size, :d
  def initialize(default_v=nil, item_klass=HeapItem)
    @d = IndexedValueArray.new
    @item_klass = item_klass
    @d[0] = @item_klass.new(nil,nil)
    @h = {}
    @size = 0
    @default_v = default_v
  end
  
	# Clears the heap
  def clear
    @d.clear
    @h.clear
    @size = 0
  end
  
  def inspect # :nodoc:
    "<HashHeap: size=#{@size.to_s}, data=#{@d[1..@size].map{|i|  [i.k,i.v]}.inspect}>" 
  end
  
	# Checks whether heap is empty
  def empty?
    @size == 0
  end
  
	# Checks whether heap includes element +k+
  def include?(k)
    @h.include?(k)
  end

  alias :has_key? :include?

  # Returns pair [k,v] which is the maximum pair according to 
  # HeapItem#<= operator.
  def extract_max
    extract_by_idx(1)
  end

  alias :extract :extract_max
 
  def extract_n(n) # :nodoc:
    res = []
    n.times do 
      p = extract
      break unless p
      res << p
    end
    res
  end
 
  def extract_subhash(n) # :nodoc:
    res = {}
    n.times do 
      k,v = extract
      break unless k
      res[k] = v
    end
    res
  end
  
  # Extracts from heap pair +[k, v]+.
  # Returns +[k, v]+ if exists, and  nil otherwise.
  def extract_by_key(k)
    if i = @h[k]
      extract_by_idx(i.idx)
    else
      nil
    end
  end

 
  alias :delete :extract_by_key
  
  def extract_by_idx(idx) # :nodoc:
    if @size >= idx
      res = @d[idx]
      @d[idx] = @d[@size]
      @h.delete(res.k)
      @size -= 1
      check_down(idx)
      check_up(idx)
      [res.k,res.v]
    else
      nil
    end
  end
  private :extract_by_idx
  
  # Should be called if value corresponding to k has been changed
  # outside of HashHeap methods.
  def update(k)
    if @h.has_key?(k)
      check_up(@h[k].idx)
      check_down(@h[k].idx)
    end
  end
  
  def first
    return nil if size == 0
    [@d[1].k, @d[1].v]
  end
  
  def keys
    @h.keys
  end
  
  def values
    @h.values
  end
  
  def each # :yields: key, value
    @h.each do |key, item|
      yield key, item.v
    end
  end
  
  def map # :yields: key, value
    @h.map do |key, item|
      yield key, item.v
    end
  end
    
  def []=(k,v)
    i = @h[k]
    if i
      i.v = v
      check_up(i.idx)
      check_down(i.idx)
    else
      i = @item_klass.new(k,v)
      @size += 1
      @d[@size] = i
      @h[k] = i
      check_up(@size)
    end
    v
  end
  
  def [](k)
    return @h[k].v if @h[k]
    @default_v
  end
  
  def check_up(c) #
    p = c/2
    while p > 0
      if @d[p] <= @d[c]
        @d[p],@d[c] = @d[c],@d[p] 
        p,c = p/2,p
      else
        break
      end
    end
  end
  
  def check_down(p)
    # STDERR.puts p
    c = 2*p
    while c <= @size
      c += 1 if c + 1 <= @size &&  @d[c] <= @d[c+1]
      if @d[p] <= @d[c]
        @d[p],@d[c] = @d[c],@d[p] 
        p,c = c,2*c
      else
        break
      end
    end
  end

  # for testing purposes
  def indexed? # :nodoc:
    (1..@size).all? {|i| @d[i].idx == i}
  end
  
  # for testing purposes 
  # besides binary relation "<" could be not linear.
  def heap? # :nodoc:
    (2..@size).all? {|i| @d[i] <= @d[i/2]}
  end
  
  private :check_up, :check_down, :indexed?, :heap?
end


# Core classes extensions.
#
class Array
  # Return n geatest elements.
  # Time asymptotics is O(size*log(n)).
  def max_n_by(n, &block)
    block ||= lambda {|i| i}
    return self.dup if self.size <= n
    h = HashHeap.new(nil, HeapItemValueMin)
    self.each do |i|
      weight = block[i]
      if h.size < n
        h[i] = weight
      else
        k,w = h.first
        if w < weight
          h.extract
          h[i] = weight
        end
      end
    end
    h.keys
  end
end

# :enddoc:
# Testing HashHeap class
if $0 == __FILE__

  class Array
    def shuffle!
      self.size.times do
        i,j = rand(size),rand(size)
        self[i],self[j] = self[j],self[i]
      end
      self
    end
  end


  require 'test/unit'
  class Ggg <Test::Unit::TestCase
    def test1
      h = HashHeap.new(nil,HeapItemValueMin)
      h2 = HashHeap.new(nil,HeapItemKeyMin)
      z = {}
      (0..10).to_a.shuffle!.each_with_index do |i,v|
        h[i] = v
        h2[i] = v
        z[i] = v
        # puts "#{i} #{v}"
      end
      assert(h.send(:heap?))
      assert(h.send(:indexed?))

      assert(h.include?(6))
      
      # puts h.inspect
      
      (0..10).each do |i|
        k,v = h.extract_max
        # puts h.inspect
        assert(h.send(:indexed?)) if i%10==0
        assert_equal(i,v)
        assert_equal([k,v], [k, z[k]])
      end
      
      (0..10).each do |i|
        k,v = h2.extract_max
        #puts "#{k} #{v}"
        assert_equal(i,k)
      end
    end
    
    def test_max_n
      a = (0..2000).to_a.shuffle!
      res = a.max_n_by(100) {|i| i % 1000}.map{|i| i % 1000}.uniq.sort
      assert_equal( (950..999).to_a,  res)
      
      a = (-100..100).to_a.shuffle!
      res = a.max_n_by(200) {|i| i.abs}.sort
      assert_equal( (a-[0]).sort,  res)
    end
  end
end


