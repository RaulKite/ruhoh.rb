require 'ruhoh/views/rmustache'
require 'ruhoh/views/helpers/page'

module Ruhoh::Views
  class Page < RMustache
    attr_reader :sub_layout, :master_layout
    attr_accessor :data
    
    def initialize(ruhoh, pointer_or_content)
      @ruhoh = ruhoh
      context.push({"master" => self})
      if pointer_or_content.is_a?(Hash)
        @data = @ruhoh.db.get(pointer_or_content)
        @data = {} unless @data.is_a?(Hash)

        raise "Page #{pointer_or_content['id']} not found in database" unless @data

        context.push(@data)
        @pointer = pointer_or_content
        @collection = Ruhoh::Resources::Resource.resources[@pointer["resource"]].const_get(:View).new(@ruhoh, context)

        # Singleton resource w/ access to resources collection and master view.
        if @collection.class.const_defined?(:Single)
          @page = @collection.class.const_get(:Single).new(@ruhoh, @data)
          @page.collection = @collection
          @page.master = self
        end
      else
        @content = pointer_or_content
        @data = {}
      end
    end
    
    # Delegate #page to the kind of resource this view is modeling.
    def page
      @page
    end
    
    def render_full
      process_layouts
      render(expand_layouts)
    end
    
    def content
      render(@content || @ruhoh.db.content(@pointer))
    end
    
    def process_layouts
      if @data['layout']
        @sub_layout = @ruhoh.db.layouts[@data['layout']]
        raise "Layout does not exist: #{@data['layout']}" unless @sub_layout
      end
    
      if @sub_layout && @sub_layout['data']['layout']
        @master_layout = @ruhoh.db.layouts[@sub_layout['data']['layout']]
        raise "Layout does not exist: #{@sub_layout['data']['layout']}" unless @master_layout
      end
      
      @data['sub_layout'] = @sub_layout['id'] rescue nil
      @data['master_layout'] = @master_layout['id'] rescue nil
      @data
    end
    
    # Expand the layout(s).
    # Pages may have a single master_layout, a master_layout + sub_layout, or no layout.
    def expand_layouts
      if @sub_layout
        layout = @sub_layout['content']

        # If a master_layout is found we need to process the sub_layout
        # into the master_layout using mustache.
        if @master_layout && @master_layout['content']
          layout = render(@master_layout['content'], {"content" => layout})
        end
      else
        # Minimum layout if no layout defined.
        layout = '{{{content}}}' 
      end
      
      layout
    end
    
    # Public: Formats the path to the compiled file based on the URL.
    #
    # Returns: [String] The relative path to the compiled file for this page.
    def compiled_path
      path = CGI.unescape(@data['url']).gsub(/^\//, '') #strip leading slash.
      path = "index.html" if path.empty?
      path += '/index.html' unless path =~ /\.\w+$/
      path
    end
    
  end #Page
end #Ruhoh