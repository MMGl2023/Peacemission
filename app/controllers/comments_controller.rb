class CommentsController < ApplicationController
  before_filter :find_comment, :only => [:destroy, :update, :show, :edit]
  before_filter :can_edit_comment_required, :only => [:destroy, :update, :edit]

  protected
  def find_comment
    @comment = Comment.find(params[:id]) || bad_request("Не могу найти комментарий")
  end

  def find_obj
    @obj = (params[:obj_type].constantize.find_by_id(params[:obj_id]) rescue nil)
  end

  public
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.paginate(
      :page => params[:page], 
      :conditions => ["root_id IS NULL"],
      :order => "created_at DESC"
    )
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    respond_to do |format|
      format.html {
        if remote?
          render :layout => false, :partial => 'comment_wrapper'
        end
      }
      format.xml  { render :xml => @comment }
    end
  end
  
  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = Comment.new(params[:comment])
    @comment.author_name ||= session[:comment_author_name]
    @comment.contacts ||= session[:comment_contacts]
     
    respond_to do |format|
      format.html {
        if remote?
          render :update do |page|
            page << "if ($('comment_form')) { Element.remove('comment_form');}"
            page.insert_html :top, comments_cdom_id, :file => 'comments/comment_form'
          end
        end
      }
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    if remote?
      render :update do |page|
        page << "if ($('comment_form')) { Element.remove('comment_form');}"
        page.replace cdom_id(@comment), :file => 'comments/comment_form'
      end
    end
  end

  # POST /comments
  # POST /comments.xml
  def create
    if params[:cancel]
      render :update do |page|
        page <<  "if ($('comment_form')) { Element.remove('comment_form');}"
      end
    else
      params[:comment] ||= {}
      if params[:comment][:contacts].blank?
        params[:comment][:contacts] = session[:comment_contacts]
      else
        session[:comment_contacts] = params[:comment][:contacts]
      end
      @comment = Comment.new(params[:comment])
      @comment.author_id = current_user.id if current_user
      @comment.session_id = session.session_id
      check_and_update
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment.update_attributes params[:comment]
    check_and_update
  end

  def check_and_update
    if session[:is_spammer] || session[:is_bot]
      if yacaph_validated?(:prefix => 'comment_') 
        session[:is_human] = true
        session[:is_bot] = nil
      else
        @comment.errors.add :captcha, "неверно"
      end
    end
    
    @comment.is_human = session[:is_human]
    @comment.is_bot = session[:is_bot]
    
    @updating = @comment.id

    respond_to do |format|
      if !params[:cancel] && @comment.errors.empty? && @comment.save
        @info = 'Комментарий был успешно добавлен.'
        session[:is_spammer] = nil
        session[:comment_author_name] = @comment.author_name
        format.html { 
          if params[:remote]  
            render :update do |page|
              if @updating
                page.replace 'comment_form', :partial => 'comment'
                page.visual_effect :highlight, cdom_id(@comment)
              else
                page.replace 'comment_form', :partial => 'comment_wrapper'
                page.visual_effect :highlight, wrapper_cdom_id(@comment)
              end
              page << 'reset_timeout();'
            end
          else
            redirect_to(@comment) 
          end
        }
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        if params[:cancel]
          render :update do |page|
            @info = 'Редактирование отменено'
            page << "if ($('message')) { Element.remove('message'); }"
            page.insert_html :top, 'comment_form', :file => 'shared/message'
            if @updating
              page.replace 'comment_form', :partial => 'comment'
            else
              page << "if( $('comment_form') ) { Element.remove('comment_form'); }"
            end
          end
        else
          format.html { 
            render :update do |page|
              @info = 'Не могу добавить комментарий'
              session[:is_spammer] = true if @comment.is_spammer
              @obj = @comment
              page << "if ($('message')) { Element.remove('message');}"
              page.insert_html :top, 'comment_form', :file => 'shared/message'
              if session[:is_spammer] || session[:is_bot]
                page.replace 'comment_form', :file => 'comments/comment_form'
              end
            end
          }
          format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  hide_action :check_and_update

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { 
        @info = "Комментарий удален"
        render :template => 'shared/message', :layout => false
      }
      format.xml  { head :ok }
    end
  end

  def update_comment(page, comment)
    @comment = comment
    html = render_to_string :partial => 'comments/comment_wrapper', :object => comment
    page << "if ( $('#{wrapper_cdom_id(comment)}') ) {"
    #  page.replace wrapper_cdom_id(comment), html
    page << "} else {"
      page.insert_html :top, comments_cdom_id(comment.obj), html
      page[ wrapper_cdom_id(comment) ].hide();
      page.visual_effect :slide_down, wrapper_cdom_id(comment), :duration=>3
    page << '}'
  end
  helper_method :update_comment
  hide_action :update_comment

  def update_comments
    if find_obj && params[:since] 
      since = Time.at(params[:since].to_i).utc
      updated = false;
      render :update do |page|
        page << "g_last_update_at = #{Time.now.to_i};"
        @obj.comments.each do |c|
          if c.created_at > since
            update_comment(page, c)
            updated = true;
          else
            c.sub_comments(since).select{|sc| sc.parent == :no || sc.parent == c}.each do |sc|
              update_comment(page, sc)
              updated = true
            end
          end
        end
        page << 'reset_timeout();' if updated
      end
    else
      bad_request
    end
  end
end

