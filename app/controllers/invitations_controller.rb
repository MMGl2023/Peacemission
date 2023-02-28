class InvitationsController < ApplicationController

  require_permission :invitations

  before_action :find_invitation, :only => [:show, :send_inv, :edit, :update]

  protected

  def find_invitation
    (@invitation = Invitation.find_by_id(params[:id]) ||
                   Invitation.find_by_email(params[:email])
    ) || bad_request('Не могу найти приглашения с указанными параметрами', previous_url || '/')
  end

  public

  # GET /invitations
  # GET /invitations.xml
  def index
    list

    respond_to do |format|
      format.html { render :action => 'list' }
      format.xml  { render :xml => @invitations }
    end
  end

  # GET /invitations/1
  # GET /invitations/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @invitation }
    end
  end

  def send_inv
    @done = Notifier.deliver_invite_user(@invitation)
    if remote?
      replace_html('<font color="green">ok!</font>')
    else
      flash[:info] = "Приглашение #{@invitation.name} (#{@invitation.email}) было отправлено."
      redirect_back_or_default( invitation_path(@invitation) )
    end
  end

  def set_default_subject
    @default_subject = "Вас пригласил :name для работы над сайтом :host" % {
       :name => current_user.full_name,
       :host => request.host
    }
  end
  # hide_action :set_default_subject

  # GET /invitations/new
  # GET /invitations/new.xml
  def new
    set_default_subject
    @host = request.host
    @invitation = Invitation.new(
      :body  => '[YOUR TEXT]',
      :email => '[EMAIL]',
      :name  => '[NAME]',
      :code  => '[CODE]',
      :subject => @default_subject
    )
    @invitation.created_by = current_user
    @letter = render_to_string :template => 'notifier/invite_user', :layout => false

    @invitation = Invitation.new(params[:invitation])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @invitation }
    end
  end

  # GET /invitations/1/edit
  def edit

  end

  # POST /invitations
  # POST /invitations.xml
  def create
    set_default_subject
    @invitation = Invitation.new(params[:invitation])

    @invitation.created_by = current_user
    if @invitation.subject.blank?
      @invitation.subject = @default_subject
    end

    respond_to do |format|
      if @invitation.save
        format.html {
          flash[:info] =  "Приглашение пользователю :user было отправлено. Можно создать ещё одно" % {
            :user => @invitation.name
          }
          redirect_to new_invitation_path
        }
        format.xml  { render :xml => @invitation, :status => :created, :location => @invitation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /invitations/1
  # PUT /invitations/1.xml
  def update
    respond_to do |format|
      if @invitation.update_attributes(params[:invitation])
        flash[:info] = 'Приглашение было обновлено'
        format.html { redirect_to(@invitation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /invitations/1
  # DELETE /invitations/1.xml
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.destroy

    respond_to do |format|
      format.html { redirect_to(invitations_url) }
      format.xml  { head :ok }
    end
  end

  def list
    @title ||= "Список приглашений"
    @wide_style = true

    cnds = conditions_from_params :invitation,
      :sort_by  => %w(name email expired_at created_at used_by_id),
      :include  => [:used_by, :created_by],
      :filter   => %w(created_by_id),
      :search_in => %w(name email body subject),
      :page     => params[:page],
      :per_page => params[:per_page] || 20

    @invitations = Invitation.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    if @invitations.size == 0 && @invitations.total_pages < cnds[:page].to_i
      cnds[:page] = @invitations.total_pages
      @invitations = Invitation.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    end
  end
end

