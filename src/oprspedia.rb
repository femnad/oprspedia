require 'erubis'
require 'nokogiri'
require 'open-uri'
require 'sinatra'
require 'set'

set :bind => "<private-ip>"
set :port => "<bind-port>"
set :show_exceptions => false

BASE_URL = "https://en.wikipedia.org"
EXPECTED_MODULE_PARAMS = Set.new ["debug", "lang", "modules", "only", "skin"]
MOBILE_HOSTNAME = "en.m.oprspedia.org"
MOBILE_PREFERENCE_PAIR = {"target" => "mobile"}
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

def params_to_query_string(params)
  as_pairs = params.to_a.map{ |kv|
    "#{kv.first}=#{kv.last}"
  }
  as_pairs.join('&')
end

def get_module_query_string(params)
  params.keep_if{ |k, v|
    EXPECTED_MODULE_PARAMS.include?(k)
  }
  params_to_query_string(params)
end

def load_module(module_params)
  query_string = get_module_query_string(module_params)
  module_link = "#{BASE_URL}/w/load.php?#{query_string}"
  module_content = open(module_link)
  module_content.read
end

def load_image_file(image_file)
  image_link = "#{BASE_URL}/static/images/#{image_file}"
  image_content = open(image_link)
  image_content.read
end

get '/wiki/:article' do
  article_name = params['article']
  erb get_article_content(article_name)
end

def set_mobile_preference(params)
  params.merge(MOBILE_PREFERENCE_PAIR)
end

get '/static/favicon/:icon_file' do
  favicon_file = params['icon_file']
  get_favicon_file(favicon_file)
end

get '/w/load.php' do
  content_type "text/css"
  mobile_requested = request.host.equal?(MOBILE_HOSTNAME)
  if mobile_requested
    params = set_mobile_preference(params)
  end
  load_module(params)
end

get '/static/images/:image_file' do
  image_file = params['image_file']
  load_image_file(image_file)
end

get '/static/images/*/:image_file' do
  image_file = params['captures'].join('/')
  load_image_file(image_file)
end
