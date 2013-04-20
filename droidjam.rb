require 'bundler/setup'
require 'sinatra'
require 'json'
require 'redis'
require_relative './band.rb'
require_relative './player.rb'
$redis = Redis.new

before do
  content_type 'application/json'
end

get '/' do
  JSON.dump "Hello world!"
end

get '/bands' do
  JSON.dump Band.all.map(&:to_h)
end

get '/bands/:id' do |id|
  band = Band.find(id)
  if band
    JSON.dump band.to_h
  else
    pass
  end
end

post '/bands' do
  body = JSON.parse(request.body.read)
  if body['id']
    raise "Can't create a band with an ID!"
  end
  band = Band.new(body).save
  JSON.dump(band)
end

delete '/bands/:id' do |id|
  Band.destroy(id)
  JSON.dump({status: "ok"})
end

delete '/bands' do
  Band.destroy_all
  JSON.dump({status: "ok"})
end

get '/players' do
  JSON.dump Player.all.map(&:to_h)
end

get '/players/:id' do |id|
  player = Player.find(id)
  if player
    JSON.dump player.to_h
  else
    pass
  end
end

post '/players' do
  body = JSON.parse(request.body.read)
  if body['id']
    raise "Can't create a player with an ID!"
  end
  player = Player.new(body).save
  JSON.dump(player)
end

delete '/players/:id' do |id|
  Player.destroy(id)
  JSON.dump({status: "ok"})
end

delete '/players' do
  Player.destroy_all
  JSON.dump({status: "ok"})
end
