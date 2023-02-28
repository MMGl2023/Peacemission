class Fitem < ActiveRecord::Base

  belongs_to :user, optional: true

  EXT_RGXP = /(\.[\w\d]+)$/
  @@dir = 'base'
  @sub_dir = 'base'

  before_save :update_file_hash, :fix_name_and_ext, :after_rename, :create_links, :update_size
  before_create :set_created_at
  before_destroy :remove_files
  validates_uniqueness_of :name, message: "должно быть уникальным"

  validates_format_of :name, with: /\A\w[\w\.\d]*\z/, message: "должно начинаться на букву и состоять из букв, цифр, знаков подчеркивания и точек"

  def self.log_cmd(cmd)
    logger.info cmd
    logger.info `#{cmd} 2>&1`
  end

  def log_cmd(*args)
    self.class.log_cmd(*args)
  end

  def update_file_hash
    self.file_hash = self.class.file_hash(self.path_name) if File.file?(self.path_name)
  end

  def image?
    self.ext =~ /\A\.(png|jpg|bmp|gif)\z/i
  end

  def ensure_size
    self.size || (
      self.size = File.size(path)
      self.update_selected_attributes(:size)
      self.size
    ) rescue 0
  end

  def update_size
    self.size = File.size(path) rescue 0
    if image?
      begin
        image = Magick::Image.read(path)
        image = image.first if image.is_a?(Array)
        self.width = image.columns
        self.height = image.rows
      rescue => e
        logger.error "ImageMagic error: #{e.message}"
      end
    end
  end

  def dims
    self.width.to_s + 'x' + self.height.to_s
  end

  def remove_files
    if File.exist?(self.path)
      [self.path, self.path_ext, self.path_name].each do |t|
        destroy_logger.info "removing '#{t}'"
        begin
          ; File.unlink(t);
        rescue Errno::ENOENT => e;
          nil
        end
      end
    else
      destroy_logger.warn "destroying fitem pointing to unexisting file '#{self.path}'"
    end
    self.class.remove_thumbs(self.name)
  end

  def create_links
    if self.id
      s = self.path
      [self.path_ext, self.path_name].each do |t|
        log_cmd "ln -f \"#{s}\" \"#{t}\""
      end
    end
  end

  def after_rename
    if self.id
      old = self.class.find_by(id: self.id)
      if old && old.name != self.name
        # convertion for images
        if old.image?
          log_cmd "convert #{old.path_ext} #{self.path_ext}"
          log_cmd "ln -f #{self.path_ext} #{self.path}"
          self.class.remove_thumbs(old.name)
          self.class.remove_thumbs(self.name)
        end
        if old.ext != self.ext
          self.content_type = Mime::Type.lookup_by_extension(self.ext.gsub('.', '')).to_s
        end
        [old.path_ext, old.path_name].each do |t|
          log_cmd "rm #{t}"
        end
      end
    end
  end

  def set_created_at
    self.created_at ||= Time.now
  end

  def fix_name_and_ext
    # Priorities: name, ext
    name.downcase!
    if self.name =~ EXT_RGXP
      self.ext = $1
    else
      self.ext ||= '.nil'
      self.name += ext
    end
  end

  class << self
    def dir
      # RAILS_ROOT + '/public/s/' + @sub_dir
      Rails.root.join('public/s/' + @sub_dir)
    end

    def sub_dir
      @sub_dir
    end

    def url(options)
      if n = options[:name]
        url_by_name(n)
      elsif i = options[:id]
        url_by_id(i)
      elsif fitem = options[:fitem]
        fitem.url
      end
    end

    def url_by_name(name)
      FILE_HOST + @sub_dir + '/' + name
    end

    def url_by_id(i)
      FILE_HOST + @sub_dir + '/ids/' + i
    end

    def path_by_name(name)
      self.dir + '/' + name
    end

    def path_by_id(i)
      self.dir + '/ids/' + name
    end

    def file_hash(file)
      Digest::MD5.file(file).hexdigest
    end

    def ensure_thumb_url(name, options = {})
      return url_by_name(name) if options.project(:ext, :dims, :width, :height).empty?
      dims = options[:dims] || (options[:width].to_s + 'x' + options[:height].to_s)
      ext = (name =~ EXT_RGXP and $1) || '.jpg'
      thumb_name = thumb_name_prefix(name) + dims + (options[:ext] || ext)
      filename = self.dir + '/' + name
      thumb_filename = self.dir + '/' + thumb_name

      if !File.exist?(thumb_filename) && File.exist?(filename)
        FileUtils.mkdir_p(File.dirname(thumb_filename))
        log_cmd "convert -resize #{dims} #{filename} #{thumb_filename}"
      end
      url_by_name(thumb_name)
    end

    def remove_thumbs(name)
      unless name.blank? && name =~ /^\w/
        pref = thumb_name_prefix(name)
        log_cmd "rm -rf #{self.dir + '/' + pref + '*'}"
      end
    end

    def thumb_name_prefix(name)
      thumb_name = 'thumbs/' + name.gsub(EXT_RGXP, '') + '.-'
    end
  end

  # for browsing
  def url
    FILE_HOST + self.class.sub_dir + '/ids/' + filename_ext + url_suffix
  end

  def url_name
    self.class.url_by_name(self.name) + url_suffix
  end

  def url_suffix
    '?' + self.ensure_file_hash[0..8]
  end

  def ensure_thumb_url(*args)
    options = extract_options(args)
    h = self.height || 100
    h = 1 if h == 0
    w = self.width || 100
    asp = w.to_f / h
    asp = 1.0 if asp == 0
    mod = false
    if options[:max_width] && w > options[:max_width]
      w = options[:max_width]
      h = (w / asp).round
      mod = true
    end
    if options[:max_height] && h > options[:max_height]
      h = options[:max_height]
      w = (h * asp).round
      mod = true
    end
    if mod
      options[:width] = w unless options[:width] && options[:width] < w
      options[:height] = h unless options[:height] && options[:height] < h
    end
    args << options unless options.blank?
    self.class.ensure_thumb_url(self.name, *args) + url_suffix
  end

  def ensure_file_hash
    self.file_hash ||= self.class.file_hash(self.path) rescue ''
  end

  #  virtual attribute for active scaffold
  def url=(u) end

  def self.with_stream_or_file(stream, &block)
    if stream.respond_to?(:path) && !stream.path.blank?
      block[stream.path]
    elsif stream.respond_to?(:read)
      tmp = Tempfile.new('fitem')
      File.open(tmp.path, 'w+') { |f| f.write(stream.read) }
      block[tmp.path]
      tmp.close
    elsif stream.is_a?(String) && File.exist?(stream)
      block[stream]
    else
      raise ArgumentError, "Don't know how to read stream or file '#{stream.inspect}'"
    end
  end

  def update_from_stream(stream, attrs = {})
    Fitem.with_stream_or_file(stream) do |path|
      FileUtils.cp(path, self.path)
      FileUtils.chmod 0666, self.path
    end
    self.original_filename = stream.original_filename if stream.respond_to?(:original_filename)
    new_ext = attrs[:ext]
    if !new_ext && self.original_filename =~ EXT_RGXP
      new_ext = $1.downcase
    end
    if new_ext != self.ext
      self.name.sub!(EXT_RGXP, new_ext)
    end
    self.content_type = stream.content_type if stream.respond_to?(:content_type)
    self.create_links
    self.save
  end

  def self.create_from(stream, attrs = {})
    fitem = nil
    attrs[:original_filename] ||= stream.original_filename if stream.respond_to?(:original_filename)
    attrs[:content_type] ||= stream.content_type if stream.respond_to?(:content_type)
    dims_options = attrs.project(:max_width, :max_width)
    attrs.except!(:max_height, :max_width)
    begin
      fitem = self.new(attrs)
      with_stream_or_file(stream) do |path|
        logger.info "Placing in repository '#{path}', #{attrs.inspect}."
        fitem.original_filename ||= File.basename(path)
        if fitem.original_filename =~ EXT_RGXP
          fitem.ext ||= $1.downcase
        end

        fitem.ext ||= '.nil'
        fitem.name ||= fitem.original_filename

        fitem.name.sub!(EXT_RGXP, fitem.ext) || fitem.name += fitem.ext
        if attrs && self.find_by_name(attrs[:name])
          fitem.errors.add :name, "File item with name '#{attrs[:name]}' exists."
          return fitem
        else
          if fitem.save # now we have id
            d = File.dirname(fitem.path)
            FileUtils.mkdir_p(d, mode: 0777)
            logger.info "Creating fitem #{fitem.path} from #{stream}"
            FileUtils.cp(path, fitem.path)
            FileUtils.chmod 0666, fitem.path
            fitem.create_links
          else
            return fitem
          end
        end
      end
    rescue => e
      fitem ||= self.new()
      if stream.blank?
        fitem.errors.add :file, "File is not specified"
      else
        fitem.errors.add :name, "Can't load file. #{e.to_s}"
      end
    end
    fitem.change_dims(dims_options)
    fitem
  end

  def change_dims(options = {})
    max_width, max_height = options.values_at(:max_width, :max_height)
    if self.image? && (max_width || max_height) && (self.width && self.height)
      if max_width && self.width < max_width
        `convert -resize #{max_width}x  #{self.path_ext} #{self.path_ext}`
      end
      if max_height && self.height < max_height
        `convert -resize x#{max_height}  #{self.path_ext} #{self.path_ext}`
      end
    end
    self.update_size
    self
  end

  def dir
    self.class.dir
  end

  def path
    # self.dir + '/ids/' + self.filename
    self.dir + 'ids/' + self.filename
  end

  def path_name
    # self.dir + '/' + (self.name || 'ids/' + self.id.to_s)
    self.dir + '' + (self.name || 'ids/' + self.id.to_s)
  end

  def path_ext
    Pathname(self.path.to_s + self.ext.to_s)
  end

  def filename
    self.id.to_s
  end

  def filename_ext
    self.filename + self.ext
  end

  def destroy_logger
    @destroy_logger ||= Logger.new(File.dirname(__FILE__) + '/../../log/file_item_remove.log')
  end

  def lib_config
    return @@config if defined?(@@config) && @@config
    self.class.config
  end

  def self.lib_config
    return @@config if defined?(@@config) && @@config
    @@config = YAML.load_file(File.dirname(__FILE__) + '/../../config/library.yml')
    if @@config['library']['root'][0..0] != '/'
      @@config['library']['root'] = File.dirname(__FILE__) + '/../../' + @@config['library']['root']
    end
    @@config
  end
end

unless Digest::MD5.respond_to? :file
  module Digest
    class MD5
      # creates a digest object and reads a given file, _name_.
      #
      #  p Digest::SHA256.file("X11R6.8.2-src.tar.bz2").hexdigest
      #  # => "f02e3c85572dc9ad7cb77c2a638e3be24cc1b5bea9fdbb0b0299c9668475c534"
      def self.file(name)
        new.file(name)
      end

      # updates the digest with the contents of a given file _name_ and
      # returns self.
      def file(name)
        File.open(name, 'rb') { |f|
          buf = ''
          while f.read(16384, buf)
            update buf
          end
        }
        self
      end
    end
  end
end
