class Report < ActiveRecord::Base
  belongs_to :user, optional: true
  has_many :fitems, as: :owner, dependent: :destroy

  validates_presence_of :email

  validates_format_of :email,
                      with: /\A([^@\s]+|"[^@]+")@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
                      message: :has_wrong_format

  validates_each :details, :subject do |record, name, value|
    Comment.validate_bad_words_record(record, name, value)
  end

end

