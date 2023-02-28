class AnketsController < ApplicationController
  # GET /ankets
  # GET /ankets.xml

  def index
    render_topic 'ankets_index'
  end

  def list
    @ankets = Anket.paginate(:page=>params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ankets }
    end
  end

  # GET /ankets/1
  # GET /ankets/1.xml
  def show
    @anket = Anket.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @anket }
    end
  end

  # GET /ankets/new
  # GET /ankets/new.xml
  def new
    @anket = Anket.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @anket }
    end
  end

  # GET /ankets/1/edit
  def edit
    @anket = Anket.find(params[:id])
  end

  # POST /ankets
  # POST /ankets.xml
  def create
    @anket = Anket.new(params[:anket])

    respond_to do |format|
      if @anket.save
        flash[:info] = 'Anket was successfully created.'
        format.html { redirect_to(@anket) }
        format.xml  { render :xml => @anket, :status => :created, :location => @anket }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @anket.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ankets/1
  # PUT /ankets/1.xml
  def update
    @anket = Anket.find(params[:id])

    respond_to do |format|
      if @anket.update_attributes(params[:anket])
        flash[:info] = 'Anket was successfully updated.'
        format.html { redirect_to(@anket) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @anket.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ankets/1
  # DELETE /ankets/1.xml
  def destroy
    @anket = Anket.find(params[:id])
    @anket.destroy

    respond_to do |format|
      format.html { redirect_to(ankets_url) }
      format.xml  { head :ok }
    end
  end
end
