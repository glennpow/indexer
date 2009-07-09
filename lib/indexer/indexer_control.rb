module IndexerControl
  def create_indexer(klass = nil, &block)
    klass ||= controller_name.singularize.camelize.constantize
    options = Indexer.parse_options(params)
    block.call(options)
    Indexer.new(klass, options)
  end

  def respond_with_indexer(klass = nil, &block)
    @indexer = create_indexer(klass, &block)
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @indexer.collection }
      format.js do
        render :update do |page|
          replace_indexer page, @indexer
        end
      end
    end
  end
end

ActionController::Base.send(:include, IndexerControl) if defined?(ActionController::Base)