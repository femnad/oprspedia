require 'erubis'
require 'nokogiri'
require 'net/http'
require 'sinatra'
require 'set'

set :show_exceptions => false

BASE_URL = "https://en.wikipedia.org"
EXPECTED_MODULE_PARAMS = Set.new ["debug", "lang", "modules", "only", "skin", "target"]
MOBILE_HOSTNAME = "en.m.oprspedia.org"
MOBILE_PREFERENCE_PAIR = {"target" => "mobile"}
WIKI_URL = "#{BASE_URL}/wiki"

def get_favicon_path(icon_file)
  "#{BASE_URL}/static/favicon/#{icon_file}"
end

def get_uri_content(uri_string)
  uri = URI(uri_string)
  Net::HTTP.get(uri)
end

def get_favicon_file(icon_file)
  favicon_path = get_favicon_path(icon_file)
  get_uri_content(favicon_path)
end

def get_article_content(article_name)
  article_link = "#{WIKI_URL}/#{article_name}"
  encoded_link = URI.encode(article_link)
  get_uri_content(encoded_link)
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
  get_uri_content(module_link)
end

def load_image_file(image_file)
  image_link = "#{BASE_URL}/static/images/#{image_file}"
  get_uri_content(image_link)
end

get '/wiki/:article' do
  article_name = params['article']
  erb get_article_content(article_name)
end

def set_mobile_preference(params)
  params.merge(MOBILE_PREFERENCE_PAIR)
end

def optionally_update_for_mobile(params, mobile_requested)
  if mobile_requested
    return set_mobile_preference(params)
  else
    return params
  end
end

get '/static/favicon/:icon_file' do
  favicon_file = params['icon_file']
  get_favicon_file(favicon_file)
end

get '/w/load.php' do
  content_type "text/css"
  mobile_requested = request.host.eql?(MOBILE_HOSTNAME)
  final_params = optionally_update_for_mobile(params, mobile_requested)
  load_module(final_params)
end

get '/static/images/:image_file' do
  image_file = params['image_file']
  load_image_file(image_file)
end

get '/static/images/*/:image_file' do
  image_file = params['captures'].join('/')
  load_image_file(image_file)
end
