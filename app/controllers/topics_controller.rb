class TopicsController < ApplicationController
  include AuthenticationSystem

  @@cfg = APP_CONFIG['topics']

  before_action :signin_if_not_yet, except: %i[show index search news]

  before_action :find_and_check_topic, only: %i[update edit show show_auth destroy]

  caches_page :show, if: :allow_topic_caching?

  #  caches_action :news, if: :allow_news_caching?, tag: :action_and_login_and_page_tag

  # cache_sweeper :topic_sweeper, only: %i[update create]

  protected

  def allow_topic_caching?
    flash.blank? && !authenticated?
  end

  def allow_news_caching?
    [:topic_s, :author].all? { |p| params[p].blank? } &&
      flash.blank? &&
      (params[:section].blank? || params[:section] == 'news') &&
      (
        (params[:sort].blank? && params[:sort_dir].blank?) ||
          (params[:sort] == 'published_at' && params[:sort_dir] == 'desc')
      )
  end

  public

  def find_and_check_topic
    if params[:id] !~ /^\d+$/
      params[:name] ||= params.delete(:id)
    end

    if !(params[:id] && @topic = Topic.find_by_id(params[:id])) and
      !(params[:name] && @topic = Topic.find_by_name(params[:name]))
    then
      if current_user
        @error = "Не могу найти страницу с name=#{params[:name] || '*'} и id=#{params[:id] || '*'}. Хотите <a href=\"/topics/new?name=#{params[:name]}\">создать</a> такую страницу?"
      else
        @error = "Не могу найти страницу #{params[:name] || '*'}/#{params[:id] || '*'}"
      end
      bad_request(@error)
    else
      unless @topic.ensure_permissions.empty?
        check_permission(*@topic.ensure_permissions)
      end
    end
  end

  def message
    render :template => 'shared/message'
  end

  def index
    list
    @wide_style = false
  end

  def search
    @title ||= 'Поиск по сайту'
    list
    @wide_style = false
    @show_summary = true
    render :action => 'index'
  end

  def news
    no_user_menu = false
    @title ||= 'Новости'
    params[:section] = 'news'
    @show_summary = true
    params[:per_page] ||= 10
    list
    @wide_style = false
    render :action => 'index'
  end

  def destroy
    @topic.destroy
    logger.info "REMOVING TOPIC:\n" + @topic.inspect
    flash[:info] = "Страница #{@topic.name} успешно удалена"
    redirect_to list_topics_path
  end

  def new
    render :action => 'birth'
  end

  def edit
    @topic.attributes = params[:topic] if params[:topic].present?
    if @topic.locked_at &&
      (secs = Time.now - @topic.locked_at) < @@cfg['lock_seconds'] &&
      current_user.id != @topic.locked_by_id &&
      params[:unlock].blank?

      user = @topic.locked_by.login rescue "unknown"
      flash[:info] = "Страница редактируется пользователем #{user}.
        Подождите, пока пользователь закончит редактирование.
        Через #{"%.2f" % secs / 60.0} минут запрет на редактирование автоматически снимется.<br/>
        Тем не менее, вы можете
          насильно <a href=\"/topics/#{@topic.id}/edit?unlock=1\">Открыть на редактирование</a>
      ".html_safe
      redirect_to i_topic_path(@topic)
    else
      @topic.locked_by = current_user
      @topic.locked_at = Time.now
      @topic.update_selected_attributes(:locked_at, :locked_by_id)
      @topic.published_at ||= Time.now
    end
  end

  def show
    @wide_style = true if @topic.wide_style
    if current_user
      redirect_to i_topic_path(@topic)
    end
  end

  # for logged in users; no caching
  def show_auth
    @wide_style = true if @topic.wide_style
    if params[:unlock]
      @topic.locked_at = nil
      @topic.update_selected_attributes(:locked_at)
    end
    if params[:rev] && @topic.rev.to_s != params[:rev]
      TopicRevision.restore_topic(@topic, params[:rev])
      @topic.restored = true
    end
    render :action => 'show'
  end

  def rollback
    if params[:rev]
      TopicRevision.restore_topic(@topic, params[:rev])
      @topic.comment = "Возвращение к версии #{params[:rev]}"
      @topic.edited_by = current_user
      if @topic.save
        flash[:info] = "Страница успешно возвращена к версии #{params[:rev]}."
      else
        flash[:error] = "Не удалось вернуться к версии #{params[:rev]}."
      end
    else
      flash[:error] = "Не указан номер ревизии, к которой нужно вернуться."
    end
    redirect_to i_topic_path(@topic)
  end

  def update
    if params[:cancel]
      flash[:info] = "Изменения были отменены"
      redirect_to i_topic_path(@topic)
    else
      @topic.edited_by = current_user
      @topic.comment = params[:comment]
      @topic.comment ||= "Create" if @topic.rev.blank?

      if @topic.update(params.require(:topic).permit!)
        flash[:info] = "Страница была обновлена"
        redirect_to i_topic_path(@topic)
      else
        redirect_to edit_topic_path(@topic)
      end
    end
  end

  # find or create and redirect to edit
  def birth
    unless params[:name].blank?
      url_opts = {}
      if params[:name] == 'news'
        params[:name] = 'news' + (Topic.max_id + 1).to_s
        params[:section] ||= 'news'
        url_opts['topic[show_published_at]'] = 1
        url_opts['topic[section]'] = 'news'
      end
      @topic = Topic.find_or_create_by(name: params[:name])
      @topic.edited_by = current_user
      @topic.locked_by = current_user
      if @topic.save
        if @topic.name.blank?
          @topic.name = current_user.name
          @topic.update_selected_attributes(:name)
        end
        if params[:section]
          @topic.section = params[:section]
          @topic.update_selected_attributes(:section)
        end
        redirect_to edit_topic_path(@topic, url_opts)
      else
        @error = "Не могу создать страницу #{params[:name]}"
      end
    else
      @error = "Не указано имя страницы"
    end
  end

  def list
    @title ||= "Страницы сайта"
    @wide_style = true
    @title = 'Новости' if params[:section] == 'news'

    ext_params = {
      sort_by: %w(title name published_at author created_by created_at),
      search_in: %w(title name content author section),
      filter: %w(author section name),
      default_order: 'published_at DESC',
      page: params[:page],
      per_page: params[:per_page] || 20
    }

    if params[:tag]
      Tag.find_by_name(params[:tag], :include => :topics)
    end

    cnds = conditions_from_params :topic, ext_params

    @topics = Topic.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
  end
end
