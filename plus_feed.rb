# -- coding: utf-8

class PlusFeed
  class Exception < StandardError
  end
  def self.fetch_json(id)
    q = %Q![1,2,'#{id}',null,null,null,null,"social.google.com",[]]!
    url = "https://plus.google.com/_/stream/getactivities/#{id}/?sp=#{Rack::Utils.escape(q)}" 
    res = Typhoeus::Request.get(url)
    raise "couldn't find #{id}'s G+" if res.code != 200
    fakejson = res.body
    fakejson[0,5] = ""
    json = fakejson.gsub(",,", ",null,").gsub(",,", ",null,").gsub("[,", "[null,").gsub(",]", ",null]")
  end

  def initialize(json)
    @rawjson = if json.kind_of? String
      JSON.parse(json)
    else
      json
    end
    @posts = @rawjson[1][0]
  end

  def posts
    @posts.map{|post|
      permalink = "https://plus.google.com/#{post[21]}"
      desc = post[47] || post[4]
      if post[44]
        desc += %Q!<br /><br /><a href="#{post[44][1]}">#{post[44][0]}</a>  originally shared this post: !
      end
      if post[66] && post[66][0]
        if post[66][0][1]
          desc += %Q!<br /><br /><a href="#{post[66][0][1]}">#{post[66][0][3]}</a>!
        end
        if post[66][0][6]
          begin
            if post[66][0][6][0][1]['image']
              desc += %Q!<p><img src="http:#{ post[66][0][6][0][2] }"/></p>!
            else
              desc += '<a href="' + post[66][0][6][0][8] + '">' + post[66][0][6][0][8] + '</a>'
            end
          rescue
          end
        end
      end
      desc ||= permalink
      {
        :updated_at => Time.at(post[5] / 1000),
        :id => post[21],
        :description => desc,
        :link => permalink,
        :title => desc.gsub(/[<>\t\n\r]/,"")[0,40],
      }
    }
  end

  def author
    @posts[0][3]
  end

  def author_image
    "https://#{@posts[0][18]}"
  end

  def updated
    Time.at(@posts[0][5] / 1000)
  end
end
