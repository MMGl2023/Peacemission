class As::InfoController < ApplicationController
  layout 'expert'
  auto_complete_for :genre, :title
    
  def index
     @tags = ["hi", "rock"]
  end
  
end
