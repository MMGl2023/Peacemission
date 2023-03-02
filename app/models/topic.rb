class Topic < ActiveRecord::Base
  include TopicsHelper

  @@cfg = APP_CONFIG['topics']
  @@cfg[:max_revisions] ||= 20

  has_many :revisions, :class_name => 'TopicRevision'

  validates_uniqueness_of :name, :message => 'должно быть уникальным'
  validates_format_of :name, :with => /\A[a-z_][a-z\d_]+\z/,
                      :message => 'должно состоять из маленьких латинских букв, цифр и знаков подчеркивания и должно начинаться с буквы'

  before_save :correct_news, :fix_name, :extract_tags_from_tags_text

  after_save :create_revision

  after_save :remove_old_revisions

  belongs_to :locked_by, :class_name => 'User', :foreign_key => 'locked_by_id'

  attr_accessor :edited_by, :comment, :restored
  attr_accessor :old_section

  has_many :comments, -> { order("created_at") }, :as => :obj
  has_many :tags_topics
  has_many :tags, :through => :tags_topics

  class << self
    def find_all_by_tag(tag_name, options = {})
      if options[:only_ids]
        Tag.find_all_by_name(tag_name, :include => :tags_topics).map(&:tags_topics).flatten.map(&:topic_id).uniq
      else
        Tag.find_all_by_name(tag_name, :include => :topics).map(&:topics).flatten.uniq
      end
    end
  end

  def create_revision(user_id = 0)
    old_data = TopicRevision.find_last(self.id).topic_data rescue nil
    new_data = TopicRevision.topic_data(self)
    if new_data != old_data
      revision = TopicRevision.create_from_topic(self)
      self.rev = revision.rev
      self.update_selected_attributes('rev')
    end
  end

  def extract_tags_from_tags_text
    if !(self.tags_text.blank?) || !(self.tags.blank?)
      self.tags = self.tags_text.split(/\s*;;\s*/).uniq.map { |tag_text| Tag.find_by_like_or_create_by_name(tag_text) }
    end
  end

  def fix_name
    self.name.downcase!
    self.name.gsub!(/[^\w\d\-]+/, '')
  end

  def remove_old_revisions
    if self.rev && self.rev > @@cfg[:max_revisions]
      old_rev = self.rev - @@cfg[:max_revisions]
      TopicRevision.delete_all("rev < #{old_rev}")
    end
  end

  def correct_news
    if self.section == 'news'
      ensure_summary
      self.published_at ||= Time.now
    end
  end

  def published_at_string
    (self.published_at || Time.now).strftime("%Y-%m-%d %H:%M:%S")
  end

  def published_at_string=(s)
    unless s.blank?
      self.published_at = (Time.parse_ext(s) || self.published_at || Time.now)
    end
  rescue ArgumentError => e
    @published_at_invalid = true
  end

  def validate
    errors.add(:published_at, "Не корректное значение") if @published_at_invalid
  end

  def ensure_title
    self.title.blank? ? (self.name || "Topic N#{self.id}") : self.title
  end

  def ensure_summary
    self.summary.blank? ? (self.summary = summary_from_content) : self.summary
  end

  t = '(' + ['p', 'b', 'a', 'div', 'i', 'h1', 'h2', 'h3', 'h4', 'span', 'script'].join('|') + ')'
  @@remove_tags_rgxp = /\<#{t}\s*\>|\<\/#{t}\>|\<#{t}\s+[^\>\n]+\>/u

  def summary_from_content
    unless self.content.blank?
      s = self.content[0..400]
      s.gsub!(/\s+/, ' ')
      s.gsub!(@@remove_tags_rgxp, '')
      s.gsub!(/[A-Z]+\{.*?\}/, ' ')
      if s =~ /(.{110,})\.[\s\n]/
        s = $1
      elsif s =~ /(.{110,}),[\s\n]/
        s = $1
      elsif s =~ /(.{120,})[\s\n]/
        s = $1
      else
        s = (s.split(//u)[0..100].join('') rescue s[0..100])
      end
      s << '...'
    else
      ''
    end
  end

  class << self
    def render_plain_format(text)
      text = text.dup
      text.strip!
      text.gsub!(/(\n\r?[*\-] [^\n]+){2,}/) { |m| render_ulist(m) }
      text.gsub!(/(\n\r?[\d]+\. [^\n]+){2,}/) { |m| render_olist(m) }
      text.gsub!(/\n(\s*\n)+/, "\n<p>")
      text.gsub!(/[\s\n]--[\s\n]/, ' &#150; ')
      text.gsub!(/[\s\n]---[\s\n]/, ' &#151; ')

      '<p>' + text
    end

    def render_ulist(t)
      '<ul>' +
        t.gsub(/\n[*\-]\s*/, "\n<li> ") +
        '</ul>'
    end

    def render_olist(t)
      '<ol>' +
        t.gsub(/\n[\d]+\.\s*/, "\n<li> ") +
        '</ol>'
    end
  end

  attr_accessor :parse_errors

  def formatted_content(helper = nil)
    (formatted(content, helper) || '').html_safe
  end

  def formatted_summary(helper = nil)
    (formatted(summary, helper) || '').html_safe
  end

  def formatted(text, helper)
    text = text.html_safe
    pre_i = 0;
    pre_h = []
    text = (text || "").gsub(/<PRE>(.+?)<\/PRE>/m) do |m|
      pre_i += 1
      pre_h << [pre_i, m]
      "PRE#{pre_i}END"
    end
    text.gsub!(/<pre>(.+?)<\/pre>/m) do |m|
      pre_i += 1
      pre_h << [pre_i, m]
      "PRE#{pre_i}END"
    end
    text.gsub!(/^\/\/([^\n]*(\n|$))/) do |m|
      pre_i += 1
      pre_h << [pre_i, $1]
      "PRE#{pre_i}END"
    end
    # return "<pre>" + text + "</pre>"

    text = (
      case engine
      when "RedCloth", 'Textile'
        RedCloth.new(text).to_html
      when "Maruku", 'Markdown'
        Maruku.new(text).to_html
      when "plain", "Plain"
        #content
        Topic.render_plain_format(text)
      when "pre"
        "<pre>\n" +
          text.gsub('&', '&amp;').
            gsub('<', '&lt;').
            gsub('>', '&gt;') +
          "\n</pre>"
      else
        # HTML, nil
        text
      end
    )

    if justified?
      text = "<div align=\"justify\">\n" + (text || '') + '</div>'
    end

    if helper
      # Helper is responsible for expanding macros related to generating HTML.
      # See topic_helper
      text = helper.parse_topic(self, text.html_safe).html_safe
    end

    pre_h.reverse.each do |pre_i, pre_tag|
      text.gsub!("PRE#{pre_i}END", pre_tag)
    end

    text
  end

  # for extract_permissions method
  include ExtractPermissions

  def ensure_permissions
    prepare_permissions unless @prepared_permissions
    @permissions ||= []
  end

  def permissions
    @permissions ||= []
  end

  def prepare_permissions
    # permissions defined by section
    if (@@cfg['authorized_sections'] || {}).has_key? self.section
      perms = @@cfg['authorized_sections'][self.section]
      perms = [perms] unless perms.is_a?(Array)
      self.permissions.push(*perms.map!(&:to_sym))
    end

    # permissions defined by macro commands in topic's content
    extract_permissions(self, (content || '').dup)
    self.permissions.uniq!
    @prepared_permissions = true
  end
end

