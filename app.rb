# coding: utf-8

require 'rubygems'

require 'sinatra'
require "sinatra/reloader"

require 'json'
require 'data_mapper'
require 'time'

require 'gcm'

enable :reloader
set :json_content_type, :js

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/messages.db")

URL = "http://13.71.156.156:4567"

GCM_API_KEY = ENV['GCM_API_KEY']

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

class User
  include DataMapper::Resource

  property :id, String, :key => true
  property :name, String
  property :token_android, Text
end

DataMapper.finalize
Message.auto_upgrade!
User.auto_upgrade!

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

  get '/test/:token/:message' do
    ok({:result => GCM.new(GCM_API_KEY).send_notification(
          [params[:token]],
          {:data => {'message' => params[:message]}})})
  end

  def ok_with_create type, &cons_post_url
    message = create_message(type, params)
    ok({"content" => message,
        "post_path" => cons_post_url.call(message)})
  end

  post '/api/:from/audios' do
    ok_with_create(:audio) {|message|
      URL + "/api/#{params[:from]}/audios/#{message[:id]}"}
  end

  post '/api/:from/stamps' do
    ok_with_create(:stamp) {|message|
      URL + "/api/#{params[:from]}/stamps/#{message[:id]}"}
  end

  def notify token, message
    return unless token

    GCM.new(GCM_API_KEY).send_notification(
      [token],
      {:data => {'message' => message}})
  end

  def ok_with_binary_save id, path, url
    File.open(path, "wb") do |f|
      f.write(request.body.read)
    end

    message = Message.get(id)
    message.url = url
    message.save

    user = User.get(message.to)
    notify user.token_android, "メッセージが届きました!" if user

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
                 Message.all(:order => [ :id.asc ],
                             :created_at.lt => Time.parse(params[:since]),
                             :limit => limit)
               else
                 Message.all(:order => [ :id.asc ], :limit => limit)
               end
    messages.map {|message|
      message.attributes
    }.to_json
  end

  post '/api/:user/token/android' do
    user = User.first_or_create(:id => params[:user])
    user.token_android = params[:token]
    user.save
  end
end

