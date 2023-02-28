class HomeController < ApplicationController
  def index
    render_topic "index", :skip_title=>true 
  end

  def urgent_steps
    render_topic 'urgent_steps'
  end

  def documents
    render_topic 'documents'
  end
end
