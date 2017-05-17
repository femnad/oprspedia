require 'erubis'
require 'nokogiri'
require 'open-uri'
require 'sinatra'

set :bind => "<private-ip>"
set :port => "<bind-port>"
set :show_exceptions => false

BASE_URL = "https://en.wikipedia.org/wiki"

get '/wiki/:article' do
    article_link = "#{BASE_URL}/#{params['article']}"
    content = open(article_link)
    erb content.read
end
