class PeopleRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :request
end
