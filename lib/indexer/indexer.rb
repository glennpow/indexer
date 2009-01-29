class Indexer
  cattr_accessor :paginate_per_page
  
  self.paginate_per_page = 20

  attr_reader :collection
  attr_accessor :klass, :as, :row, :query, :sort, :sort_in, :locals, :headers, :footers, :more_path, :more_text,
    :options, :selectable, :paginate_options, :render_options, :search, :map

  def initialize(klass, options = {})
    self.query = options.delete(:query)
    options[:page] = (options[:page] || 1).to_i
    options[:per_page] = (options[:per_page] || Indexer.paginate_per_page).to_i
  
    self.headers = options.delete(:headers) || []
    self.sort = options.delete(:sort) || options.delete(:default_sort)
    self.sort_in = options.delete(:sort_in) || :asc
    options[:include] = [ options[:include] || [] ].flatten
    if self.sort
      self.sort = self.sort.to_sym
      sort_header = self.headers.detect { |header| header.is_a?(Hash) && header[:sort] == self.sort }
      if sort_header
        sort_order = (sort_header[:order] || "#{klass.table_name}.#{sort_header[:sort]}").to_s
        options[:include] << sort_header[:include] if sort_header[:include]
        sort_order << " #{self.sort_in}"
        options[:order] = options[:order] ? "#{sort_order}, #{options[:order]}" : sort_order
      end
    end
  
    self.klass = klass
    self.render_options = {}
    [ :no_table, :spacer_template ].each { |key| self.render_options[key] = options.delete(key) }
    self.as = options.delete(:as) || ActionController::RecordIdentifier.singular_class_name(klass)
    self.row = options.delete(:row) || "#{ActionController::RecordIdentifier.plural_class_name(klass)}/#{self.render_options[:no_table] ? 'indexed' : 'row'}"
    self.locals = (options.delete(:locals) || {}).merge({ :indexer => self })
    self.selectable = options[:selectable].nil? ? false : options.delete(:selectable)
    self.headers.unshift("") if self.selectable
    self.footers = options.delete(:footers) || []
    self.more_path = options.delete(:more_path)
    self.more_text = options.delete(:more_text)
    self.paginate_options = options.delete(:paginate)
    self.search = options.delete(:search)
    if self.search
      self.search = {} unless self.search.is_a?(Hash)
      self.search.reverse_merge!({ :url => { :action => 'index' },
        :options => { :method => :get },
        :name => :query,
        :query => self.query,
        :label => I18n.t(:search),
        :context => nil
      })
    end
    self.map = options.delete(:map)
    self.options = options

    if self.query
      @collection = klass.search(self.query, options)
    else
      options.delete(:search_include)
      @collection = klass.paginate(options)
    end
    
    @collection.map! { |record| self.map.call(record) } if self.map
  end

  def as=(arg)
    @as = arg.to_sym
  end

  def footers=(arg)
    @footers = (arg.nil? ? nil : [ arg ].flatten)
  end

  def div_id
    "indexer_#{klass.to_s.downcase}"
  end

  def form_id
    "#{self.div_id}_form"
  end

  def self.parse_options(params)
    options = {}
    [ :query, :page, :per_page, :sort, :sort_in ].each { |key| options[key] = params[key] }
    options
  end
end
