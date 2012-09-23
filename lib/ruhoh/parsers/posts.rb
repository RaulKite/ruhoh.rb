class Ruhoh
  module Parsers
    class Posts < Base
      
      def paths
        [@ruhoh.paths.base]
      end
      
      def glob
        "#{Ruhoh.names.posts}/**/*.*"
      end
      
      def is_valid_page?(filepath)
        return false if FileTest.directory?(filepath)
        return false if ['.'].include? filepath[0]
        @ruhoh.config.posts_exclude.each {|regex| return false if filepath =~ regex }
        true
      end

      class Modeler < BaseModeler
        include Page
        
        DateMatcher = /^(.+\/)*(\d+-\d+-\d+)-(.*)(\.[^.]+)$/
        Matcher = /^(.+\/)*(.*)(\.[^.]+)$/

        def generate
          type = "post"
          parsed_page = self.parse_page_file
          data = parsed_page['data']
  
          filename_data = self.parse_page_filename(@id)
          if filename_data.empty?
            #error = "Invalid Filename Format. Format should be: my-post-title.ext"
            #invalid << [@id, error] ; next
          end
  
          data['date'] ||= filename_data['date']

          unless self.formatted_date(data['date'])
            #error = "Invalid Date Format. Date should be: YYYY-MM-DD"
            #invalid << [@id, error] ; next
          end

          if data['type'] == 'draft'
            return {"_type" => "draft"} if @ruhoh.config.env == 'production'
          end  
  
          data['date']          = data['date'].to_s
          data['id']            = @id
          data['title']         = data['title'] || filename_data['title']
          data['url']           = self.permalink(data)
          data['layout']        = @ruhoh.config.posts_layout if data['layout'].nil?
          data['categories']    = Array(data['categories'])
          data['tags']          = Array(data['tags'])
          data['_type']         = type

          # Register this route for the previewer
          @ruhoh.db.routes[data['url']] = data['id']

          dict = {}
          dict[@id] = data
          dict
        end

        def formatted_date(date)
          Time.parse(date.to_s).strftime('%Y-%m-%d')
        rescue
          false
        end

        def parse_page_filename(filename)
          data = *filename.match(DateMatcher)
          data = *filename.match(Matcher) if data.empty?
          return {} if data.empty?

          if filename =~ DateMatcher
            {
              "path" => data[1],
              "date" => data[2],
              "slug" => data[3],
              "title" => self.to_title(data[3]),
              "extension" => data[4]
            }
          else
            {
              "path" => data[1],
              "slug" => data[2],
              "title" => self.to_title(data[2]),
              "extension" => data[3]
            }
          end
        end

        # my-post-title ===> My Post Title
        def to_title(file_slug)
          file_slug.gsub(/[^\p{Word}+]/u, ' ').gsub(/\b\w/){$&.upcase}
        end

        # Used in the client implementation to turn a draft into a post.  
        def to_filename(data)
          File.join(@ruhoh.paths.posts, "#{Ruhoh::Urls.to_slug(data['title'])}.#{data['ext']}")
        end

        # Another blatently stolen method from Jekyll
        # The category is only the first one if multiple categories exist.
        def permalink(post)
          date = Date.parse(post['date'])
          title = Ruhoh::Urls.to_url_slug(post['title'])
          format = post['permalink'] || @ruhoh.config.posts_permalink

          if format.include?(':')
            filename = File.basename(post['id'], File.extname(post['id']))
            category = Array(post['categories'])[0]
            category = category.split('/').map {|c| Ruhoh::Urls.to_url_slug(c) }.join('/') if category

            url = {
              "year"       => date.strftime("%Y"),
              "month"      => date.strftime("%m"),
              "day"        => date.strftime("%d"),
              "title"      => title,
              "filename"   => filename,
              "i_day"      => date.strftime("%d").to_i.to_s,
              "i_month"    => date.strftime("%m").to_i.to_s,
              "categories" => category || '',
            }.inject(format) { |result, token|
              result.gsub(/:#{Regexp.escape token.first}/, token.last)
            }.gsub(/\/+/, "/")
          else
            # Use the literal permalink if it is a non-tokenized string.
            url = format.gsub(/^\//, '').split('/').map {|p| CGI::escape(p) }.join('/')
          end  

          @ruhoh.to_url(url)
        end

      end

    end
  end
end