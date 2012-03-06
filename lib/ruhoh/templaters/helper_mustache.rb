require 'pp'

class Ruhoh
  
  class HelperMustache < Mustache

    class HelperContext < Context
    
      # Overload find method to catch helper expressions
      def find(obj, key, default = nil)
        return super unless key.to_s.index('?')
      
        puts "=> Executing helper: #{key}"
        context, helper = key.to_s.split('?')
        context = context.empty? ? obj : super(obj, context)

        self.mustache_in_stack.__send__ helper, context
      end  

    end #HelperContext
  
    def context
      @context ||= HelperContext.new(self)
    end
  
    def partial(name)
      Ruhoh::DB.partials[name.to_s]
    end
  
    def debug(sub_context)
      puts "=>DEBUG:"
      puts sub_context.class
      puts sub_context.inspect
      "<pre>#{sub_context.class}\n#{sub_context.pretty_inspect}</pre>"
    end
    
    def to_tags(sub_context)
      if sub_context.is_a?(Array)
        sub_context.map { |id|
          self.context['_posts']['tags'][id] if self.context['_posts']['tags'][id]
        }
      else
        tags = []
        self.context['_posts']['tags'].each_value { |tag|
          tags << tag
        }
        tags
      end
    end
  
    def to_posts(sub_context)
      sub_context = sub_context.is_a?(Array) ? sub_context : self.context['_posts']['chronological']
    
      sub_context.map { |id|
        self.context['_posts']['dictionary'][id] if self.context['_posts']['dictionary'][id]
      }
    end
  
    def to_pages(sub_context)
      puts "=> call: pages_list with context: #{sub_context}"
      pages = []
      if sub_context.is_a?(Array) 
        sub_context.each do |id|
          if self.context[:pages][id]
            pages << self.context[:pages][id]
          end
        end
      else
        self.context[:pages].each_value {|page| pages << page }
      end
      pages
    end
    
    def to_categories(sub_context)
      if sub_context.is_a?(Array)
        sub_context.map { |id|
          self.context['_posts']['categories'][id] if self.context['_posts']['categories'][id]
        }
      else
        cats = []
        self.context['_posts']['categories'].each_value { |cat|
          cats << cat
        }
        cats
      end
    end
    
    def analytics
      analytics_config = self.context['site']['config']['analytics']
      return '' unless analytics_config && analytics_config['provider']
      code = self.partial("analytics-providers/#{analytics_config['provider']}")
      return "<h2 style='color:red'>!Analytics Provider partial for '#{analytics_config['provider']}' not found </h2>" if code.nil?

      self.render(code)
    end

    def comments
      comments_config = self.context['site']['config']['comments']
      return '' unless comments_config && comments_config['provider']
      code = self.partial("comments-providers/#{comments_config['provider']}")
      puts "comments-provders/#{comments_config['provider']}"
      return "<h2 style='color:red'>!Comments Provider partial for '#{comments_config['provider']}' not found </h2>" if code.nil?

      self.render(code)
    end
    
  end #HelperMustache
  
end #Ruhoh