module IndexerHelper
  def indexer_submit(indexer, options = {}, html_options = {})
    returning('') do |script|
      script << "any_checked = false; Form.getInputs('#{indexer.form_id}', 'checkbox').each(function(box) { any_checked = any_checked || box.checked; }); if (any_checked) {" if html_options[:allow_none] == false
      script << "if (confirm('#{html_options[:confirm]}')) {" if html_options[:confirm]
      script << "document.#{indexer.form_id}.action = '#{url_for(options)}'"
      script << ";document.#{indexer.form_id}.method = '#{html_options[:method]}'" if !html_options[:method].nil?
      script << ";document.#{indexer.form_id}.submit()"
      script << "}" if html_options[:confirm]
      script << "} else { alert('#{t(:no_selection, :scope => [ :indexer ])}'); }" if html_options[:allow_none] == false
    end
  end
  
  def render_indexer(indexer, options = {})
    locals = indexer.render_options.merge(options).merge({ :indexer => indexer })
    render :partial => 'indexer/indexer', :locals => locals
  end
  
  def replace_indexer(page, indexer, options = {})
    locals = indexer.render_options.merge(options).merge({ :indexer => indexer })
    page.replace indexer.div_id, :partial => 'indexer/indexer', :locals => locals
  end
  
  def render_paginate(indexer_or_collection, options = {})
    case indexer_or_collection
    when Indexer
      indexer = indexer_or_collection
      collection = indexer.collection
    when WillPaginate::Collection
      indexer = nil
      collection = indexer_or_collection
    else
      indexer = nil
      collection = nil
    end
    
    if collection
      options = indexer.paginate_options.merge(options) if indexer && indexer.paginate_options
      search = options.delete(:search) || false

      if collection.total_entries > 0
        results = tt(:results, :scope => [ :indexer ], :from => collection.offset + 1, :to => collection.offset + collection.length, :total => collection.total_entries)
      else
        results = t(:no_results, :scope => [ :indexer ])
      end
      
      if indexer.nil? || indexer.more_path.blank?
        options[:next_label] ||= t(:next, :scope => [ :indexer ])
        options[:previous_label] ||= t(:previous, :scope => [ :indexer ])
        options[:container] = false
        links = will_paginate(collection, options)
      else
        more_text = indexer.more_text || t(:more)
        links = link_to(more_text, indexer.more_path)
      end

      locals = {
        :indexer => indexer,
        :results => results,
        :links => links,
        :top_paginate => options[:top_paginate] ||= false
      }
      render :partial => 'indexer/paginate', :locals => locals
    end
  end

  def sort_header(indexer, header)
    case header
    when String
      text = header  
    when Hash
      text = header[:name] || ''
      sort = header[:sort]
    end
    if sort.blank?
      text
    else
      current_sort = (sort == indexer.sort)
      sort_in = (current_sort && :desc.to_s != indexer.sort_in) ? :desc : :asc
      sort_url = url_for(:params => params.merge({ :sort => sort, :sort_in => sort_in, :page => nil }))
      class_name = "sort-header#{current_sort ? (sort_in == :asc ? ' desc' : ' asc' ) : ''}"
      link_to(text, sort_url, :class => class_name)
    end
  end
  
  def render_row(indexer, object, columns, options = {})
    columns.map! do |column|
      content = (column.is_a?(Hash) ? column[:content] : column).to_s
      content.gsub!(/<a [^>]*onclick=['"][^>]*>(.|\n)+<\/a>/) { |s| "<p onclick='event.cancelBubble = true; if (event.stopPropagation) event.stopPropagation();'>#{s}</p>" }
      column.is_a?(Hash) ? column.reverse_merge(:content => content) : { :content => content }
    end
    (actions = actions_for(options[:actions])).map! do |action|
      logger.info("ACTION=#{action}")
      logger.info("MATCH=#{action.match(/<a [^>]*onclick=['"][^>]*>(.|\n)+<\/a>/)}")
      action.gsub(/<a [^>]*onclick=['"][^>]*>(.|\n)+<\/a>/) { |s| "<p onclick='event.cancelBubble = true; if (event.stopPropagation) event.stopPropagation();'>#{s}</p>" }
    end
    
    locals = {
      :indexer => indexer,
      :object => object,
      :columns => columns,
      :headers => options[:headers],
      :actions => actions,
      :row_class => cycle('odd', 'even'),
      :row_url => options.has_key?(:url) ? options[:url] : url_for(object)
    }
    render :partial => 'indexer/row', :locals => locals
  end
  
  def actions_for(actions)
    # TODO - get rid of Hash variation
    (actions || []).flatten.map { |action| action.is_a?(Hash) ? ((!action.has_key?(:if) || action[:if]) ? action[:allow] : nil) : action }.flatten.compact
  end
end