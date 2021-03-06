require 'erubis'
require 'net/http'
require 'sinatra'
require 'set'

set :show_exceptions => false

BASE_URL = "https://en.wikipedia.org"
EXPECTED_MODULE_PARAMS = Set.new ["debug", "lang", "modules", "only", "skin", "target"]
MAIN_PAGE_SUFFIX = '/wiki/Main_Page'
MOBILE_HOSTNAME = "en.m.oprspedia.org"
MOBILE_PREFERENCE_PAIR = {"target" => "mobile"}
REPLACEMENTS = {'upload.wikimedia.org' => 'upload.oprspedia.org'}
SEARCH_URL = "https://en.wikipedia.org/w/index.php?"
WIKI_URL = "#{BASE_URL}/wiki"
WIKIMEDIA_URI_PREFIX = 'https://upload.wikimedia.org/wikipedia'

def get_favicon_path(icon_file)
  "#{BASE_URL}/static/favicon/#{icon_file}"
end

def perform_replacements(content)
  replaced_content = String.new
  REPLACEMENTS.each{ | pattern, replacement |
    replaced_content = content.gsub(pattern, replacement)
  }
  return replaced_content
end

def perform_reverse_replacements(content)
  original_content = String.new
  REPLACEMENTS.each{ | pattern, replacement |
    original_content = content.gsub(replacement, pattern)
  }
  return original_content
end

def get_uri_from_string(uri_string)
  URI(URI.encode(uri_string))
end

def get_uri_content(uri_string)
  uri = get_uri_from_string(uri_string)
  unmodified_content = Net::HTTP.get(uri)
  perform_replacements(unmodified_content)
end

def get_favicon_file(icon_file)
  favicon_path = get_favicon_path(icon_file)
  get_uri_content(favicon_path)
end

def get_article_content(article_name)
  get_uri_content("#{WIKI_URL}/#{article_name}")
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

def get_wikimedia_content(path)
  get_uri_content("#{WIKIMEDIA_URI_PREFIX}/#{path}")
end

def get_search_response(query_string)
  get_uri_content("#{SEARCH_URL}?#{query_string}")
end

def get_extension(file_name)
    last_dot_index = file_name.rindex('.')
    file_name.slice(last_dot_index..-1).downcase
end

def get_captured_path(params)
  params['captures'].join('/')
end

get '/' do
  redirect to(MAIN_PAGE_SUFFIX)
end

get '/wiki/*' do
  captured_path = get_captured_path(params)
  erb get_article_content(captured_path)
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

get '/wikipedia/*' do
  captures = params['captures']
  extension = get_extension(captures.last)
  content_type "image/#{extension}"
  path = captures.join('/')
  get_wikimedia_content(path)
end

get '/w/index.php' do
  search_query = params_to_query_string(params)
  get_search_response(search_query)
end
