require 'rubygems'

require 'sinatra'
require "sinatra/reloader"

require 'json'
require 'data_mapper'
require 'time'

enable :reloader
set :json_content_type, :js

store = {'papa' =>  [], 'mama' => [], 'child' => []}

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/messages.db")

class Message
  include DataMapper::Resource
  property :id, Serial
  property :from, String
  property :to, String
  property :type, Text
  property :message, Text
  property :created_at, DateTime
end

DataMapper.finalize
Message.auto_upgrade!

class AnoneApp < Sinatra::Base
  def ok body = {}
    content_type :json
    res = body.dup
    res["status"] = "ok"
    res.to_json
  end

  get '/' do
    'Hello anone app!'
  end

  def create_message type, params
    Message.create(
      :type => type,
      :from => params[:from],
      :to => params[:from],
      :created_at => Time.now
    )
  end

  def ok_with_create type, &cons_post_url
    message = create_message(type, params)
    ok({"content" => message,
        "post_path" => cons_post_url.call(message)})
  end

  post '/api/:from/audios' do
    ok_with_create(:audio) {|message|
      "/api/#{params[:from]}/audios/#{message[:id]}"}
  end

  post '/api/:from/stamps' do
    ok_with_create(:stamp) {|message|
      "/api/#{params[:from]}/stamps/#{message[:id]}"}
  end

  def ok_with_binary_save path
    File.open(path, "wb") do |f|
      f.write(request.body.read)
    end
    ok
  end

  post '/api/:from/audios/:id' do
    ok_with_binary_save "./data/#{params[:id]}.wav"
  end

  post '/api/:from/stamps/:id' do
    ok_with_binary_save "./data/#{params[:id]}.png"
  end

  get '/api/:user/messages' do
    messages = if params[:since]
                 since = 
                 Message.all(:order => [ :id.asc ],
                             :created_at.gt => Time.parse(params[:since]),
                             :limit => 20)
               else
                 Message.all(:order => [ :id.asc ], :limit => 20)
               end
    messages.to_json
  end
end
