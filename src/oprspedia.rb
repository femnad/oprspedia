require 'erubis'
require 'nokogiri'
require 'open-uri'
require 'sinatra'

set :bind => "<private-ip>"
set :port => "<bind-port>"
set :show_exceptions => false

BASE_URL = "https://en.wikipedia.org"
WIKI_URL = "#{BASE_URL}/wiki"

def get_favicon_path(icon_file)
  "#{BASE_URL}/static/favicon/#{icon_file}"
end

def get_favicon_file(icon_file)
  favicon_path = get_favicon_path(icon_file)
  icon_file = open(favicon_path)
  icon_file.read
end

def get_article_content(article_name)
    article_link = "#{WIKI_URL}/#{params['article']}"
    content = open(article_link)
    content.read
end

get '/wiki/:article' do
  article_name = params['article']
  erb get_article_content(article_name)
end

get '/static/favicon/:icon_file' do
  favicon_file = params['icon_file']
  get_favicon_file(favicon_file)
end
