class Lost < ActiveRecord::Base
  has_many :comments, -> { order("created_at") }, as: :obj

  belongs_to :image, class_name: 'Fitem', foreign_key: 'image_id', optional: true

  has_one :person, foreign_key: 'lost_id'

  validates_presence_of :full_name, :author_full_name, :details, message: 'не должно быть пустым'

  validates_presence_of :lost_on_year, :birth_year, message: 'должно содержать хотя бы год'

  validates_each :author_address, on: :create do |record, attr_name, value|
    record.errors.add attr_name, 'не должно быть пустым, либо должен быть указан e-mail' if record.author_email.blank? && record.author_address.blank?
  end

  before_destroy :destroy_image

  def destroy_image
    self.image.destroy if self.image
  end

  def formatted_details
    (self.details ||= '').gsub(/\n(\s*\n)+/, "\n<p>")
  end
end
