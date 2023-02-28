class As::InvitationController < ApplicationController
  layout 'expert'

  require_permission :invitations

  active_scaffold :invitation do |config|
    # config.columns << :code
    config.columns = [:created_by, :created_at, :name, :email, :expired_at, :used_by, :used_at, :subject, :text]
    
    config.list.columns << :send_inv
    
    config.columns[:created_by].search_sql = 'users.first_name'
    
    config.update.columns.exclude :used_at
    config.update.columns.exclude :created_at

    config.columns[:used_by].ui_type = :select
    config.columns[:created_by].ui_type = :select

    config.search.columns = [:name, :text, :created_by, :email]
  end

  def send_inv
    inv_id = params[:id] || params[:inv]
    if @invitation = Invitation.find_by_id(inv_id)
      Notifier.deliver(Notifier.create_invite_user(@invitation, request.host))
      @invitation.expired_at = Time.now + 14.days 
      @invitation.save
      flash[:info] = "Invitation was resend to #{@invitation.email}"
    else
      flash[:error] = "Can't find invitation with id=#{inv_id}"
    end
    redirect_to :action=>'index'
  end

end
