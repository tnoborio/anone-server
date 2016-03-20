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

URL = "http://13.71.156.156:4567"

class Message
  include DataMapper::Resource

  property :id, Serial
  property :from, String
  property :to, String
  property :type, Text
  property :message, Text
  property :url, Text
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
      :to => params[:to],
      :message => params[:message],
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

  def ok_with_binary_save id, path, url
    File.open(path, "wb") do |f|
      f.write(request.body.read)
    end

    message = Message.get(id)
    message.url = url
    message.save

    ok
  end

  post '/api/:from/audios/:id' do
    id = params[:id]
    ok_with_binary_save id,
                        "./data/#{id}.wav",
                        URL + "/api/messages/#{id}.wav"
  end

  post '/api/:from/stamps/:id' do
    id = params[:id]
    ok_with_binary_save id,
                        "./data/#{id}.png",
                        URL + "/api/messages/#{id}.png"
  end

  get '/api/messages/:id.:type' do
    message = Message.get(params[:id])
    if message && message.type == 'audio' && message.url
      send_file "./data/#{message[:id]}.wav"
    elsif message && message.type == 'stamp' && message.url
      send_file "./data/#{message[:id]}.png"
    else
      pass
    end
  end

  get '/api/:user/messages' do
    limit = 1
    limit = params[:limit].to_i if params[:limit]
    messages = if params[:since]
                 since = 
                 Message.all(:order => [ :id.asc ],
                             :created_at.gt => Time.parse(params[:since]),
                             :limit => limit)
               else
                 Message.all(:order => [ :id.asc ], :limit => limit)
               end
    messages.map {|message|
      message.attributes
    }.to_json
  end
end
