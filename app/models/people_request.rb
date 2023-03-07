class PeopleRequest < ActiveRecord::Base
  belongs_to :person, optional: true
  belongs_to :request, optional: true
end
