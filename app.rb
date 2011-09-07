# -- coding: utf-8

require "rubygems"
require "sinatra"
require "erubis"
require "json"
require "typhoeus"
require "#{File.dirname(__FILE__)}/plus_feed.rb"

get '/' do
  if (params[:id_or_url] || '').match /[0-9]+/
    redirect "/#{params[:id_or_url].match(/[0-9]+/)[0]}"
  end
  erubis :index
end

get '/:id_or_url' do
  halt 400 unless params[:id_or_url].match(/[0-9]+$/)
  id = Regexp.last_match.to_s
  begin
    json = PlusFeed.fetch_json(id)
    @plus = PlusFeed.new(json)
    @id = id
    @hostname = "#{request.host}:#{request.port}"
    content_type "application/atom+xml", :charset => "utf-8"
    erubis :feed, :layout => false
  rescue => ex
    status 400
    @error = ex.message
    erubis :index
  end
end
