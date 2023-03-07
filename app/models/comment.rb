class Comment < ActiveRecord::Base

  VIS_ALL = nil
  VIS_AUTH = 1

  class << self
    def bad_words_rgxp
      Regexp.new(YAML.load_file(File.join(RAILS_ROOT, 'config', 'bad_words.yml')).to_a.join('|'))
    end

    make_cached :bad_words_rgxp, :timeout => 1.hour

    def validate_bad_words_record(record, name, value)
      unless value.blank?
        links = value.scan(/((https?|ftp):\/\/[\w.]+|www\.([\w.]+))/).map { |m| m.first }
        ext_links = links.select { |l| !(l =~ /^(http:\/\/)?(www\.)?rozysk\.org/) }
        if ext_links.size >= 4 ||
          (ext_links.size >= 2 && !record.is_human) ||
          value =~ Comment.bad_words_rgxp ||
          value =~ /\<script/ ||
          value =~ /location\.(url|href|path)/ ||
          (ext_links.size > 0 && name.to_s =~ /subject|title/)
        then
          record.is_spammer = true if record.respond_to?(:is_spammer)
          record.errors.add name, "содержит текст, похожий на спам"
        end
      end
    end
  end

  belongs_to :obj, polymorphic: true, optional: true
  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true
  belongs_to :root, class_name: 'Comment', foreign_key: 'root_id', optional: true

  # has_many :comments, class_name: 'Comment', foreign_key: 'obj_id', conditions: 'obj_type = "Comment"'

  has_many :sub_comments, class_name: 'Comment', foreign_key: 'root_id'

  before_create :set_author_name, :set_auth_visibility_for_requests
  before_save :update_root, :set_visibility

  validates_presence_of :subject, :message => 'не должно быть пустым'

  validates_each :author_name do |record, attr, value|
    if record.author_id.blank?
      unless value =~ /[A-ZА-Я][a-zа-я.]{0,30}\s*[A-ZА-Я][a-zа-я.]{1,30}/
        if value.blank?
          record.errors.add :author_name, "не должно быть пустым"
        elsif value.length < 3
          record.errors.add :author_name, "cлишком короткое имя"
        elsif value =~ /[%$<>\\\]\[\/#]/
          record.errors.add :author_name,
                            "содержит недопустимые символы (используйте буквы; лучше всего писать Имя и Фамилию)"
        elsif value =~ Comment.bad_words_rgxp
          record.is_spammer = true
          record.errors.add :author_name, "содержит плохие слова"
        end
      end
    end
  end

  # fake CSS-hidden form field to detect spambots
  attr_accessor :bot_email
  attr_accessor :is_spammer, :is_human, :is_bot
  # attr_accessor :body, :subject, :author_name, :obj_type, :obj_id, :bot_email, :contacts

  validates_each :bot_email, :is_bot do |record, name, value|
    unless value.blank?
      record.is_bot = true
      record.errors.add name, "ты бот!"
    end
  end

  validates_each :body, :subject do |record, name, value|
    Comment.validate_bad_words_record(record, name, value)
  end

  attr_accessor :parent
  attr_accessor :comments

  def comments
    @comments ||= ((@sub_comments || (self.obj_id && self.obj_type != 'Comment')) ?
                     self.sub_comments.select { |c| c.obj_id == self.id } :
                     Comment.where(['obj_id = ? AND obj_type = "Comment"', self.id]).order('created_at DESC')
    )
  end

  def parent
    @parent ||= (self.obj_type == 'Comment') ? Comment.find_by_id(self.obj_id) : nil
  end

  alias :sub_comments_before_boost :sub_comments

  def sub_comments(since = nil)
    @sub_comments ||= (
      cmts = (since ?
                Comment.where(["created_at > ? AND root_id = ?", since, self.id]) :
                self.sub_comments_before_boost
      ) + [self]
      h = cmts.each { |c|
        c.comments = []
        c.parent = :no
      }.inject({}) { |h, c|
        h[c.id] = c
        h
      }
      h.each { |k, c|
        if p = h[c.obj_id]
          p.comments << c
          c.parent = p
        end
      }
      cmts.pop
      cmts
    )
  end

  def update_root
    if self.obj_type == 'Comment' && self.obj
      self.root_id = self.obj.root_id || self.obj_id
      Comment.update_all(
        self.class.send(:sanitize_sql_hash_for_assignment, :thread_updated_at => Time.now),
        :id => self.root_id
      )
    end
    self.thread_updated_at = Time.now
  end

  # inherit visibility from parent
  def set_visibility
    self.visibility ||= self.parent.visibility if self.parent
    self.visibility ||= 0
  end

  def set_auth_visibility_for_requests
    # coments for requests are visible only for authenticated users
    self.visibility = 1 if self.obj_type == 'Request'
  end

  def set_author_name
    self.author_name ||= self.author.full_name
  end

  def formatted_body
    @formatted_body ||= self.body.gsub('>', '&lt;').gsub('>', '&gt;').gsub(/\n(\s*\n)+/, "\n<p>")
  end

  def ensure_author_name
    self.author_name ||= (self.author ? self.author.full_name : 'некто')
  end
end

