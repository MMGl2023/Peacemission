class TagsTopic < ActiveRecord::Base
  belongs_to :topic, optional: true
  belongs_to :tag, optional: true
end
