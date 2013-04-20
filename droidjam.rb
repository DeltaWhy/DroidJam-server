require 'bundler/setup'
require 'sinatra'
require 'json'
require 'redis'
require_relative './band.rb'
require_relative './player.rb'
require_relative './band_player.rb'
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
  band = Band.find(id) or pass
  JSON.dump band.includes(:players).to_h
end

post '/bands' do
  body = JSON.parse(request.body.read)
  if body['id']
    halt 422, JSON.dump({error:"Can't create a band with an ID!"})
  end
  band = Band.new(body).save
  JSON.dump(band.to_h)
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
  player = Player.find(id) or pass
  JSON.dump player.to_h
end

post '/players' do
  body = JSON.parse(request.body.read)
  if body['id']
    halt 422, JSON.dump({error:"Can't create a player with an ID!"})
  end
  player = Player.new(body).save
  JSON.dump(player.to_h)
end

delete '/players/:id' do |id|
  Player.destroy(id)
  JSON.dump({status: "ok"})
end

delete '/players' do
  Player.destroy_all
  JSON.dump({status: "ok"})
end

get '/bands/:id/players' do |id|
  band = Band.find(id) or pass
  JSON.dump band.players.map(&:to_h)
end

get '/bands/:band_id/players/:id' do |band_id, id|
  band = Band.find(band_id) or pass
  band_player = band.players.find(id) or pass
  JSON.dump band_player.to_h
end

put '/bands/:band_id/players/:id' do |band_id, id|
  band = Band.find(band_id) or pass
  band_player = band.players.find(id) or pass
  hash = JSON.parse(request.body.read)
  band_player.ready = hash['ready']
  band_player.instrument = hash['instrument']
  if band_player.ready && !band_player.instrument
    halt 422, JSON.dump({error:"Can't be ready without an instrument!"})
  end
  band_player.save
  JSON.dump band_player.to_h
end

post '/bands/:id/start' do |id|
  band = Band.find(id) or pass
  band.has_started = true
  band.save

  JSON.dump band.includes(:players).to_h
end

post '/bands/:id/join' do |id|
  band = Band.find(id) or pass
  player_id = JSON.parse(request.body.read).fetch('player_id')
  player = Player.find(player_id) or pass

  band_player = band.players.create(id: player.id, name: player.name, instrument: "keys", ready: false)
  JSON.dump band_player.to_h
end

post '/bands/:id/leave' do |id|
  band = Band.find(id) or pass
  player_id = JSON.parse(request.body.read).fetch('player_id')
  band.players.destroy(player_id)

  JSON.dump({status: "ok"})
end

put '/bands/:band_id/players/:id/:file.mid' do |band_id, id, file|
  band = Band.find(band_id) or pass
  band_player = band.players.find(id) or pass
  File.open("uploads/#{band_id}-#{id}.mid", 'wb') do |f|
    f.write(request.body.read)
  end
  band_player.has_uploaded = true
  band_player.save
  
  if band.players.all?(&:has_uploaded)
    band.has_finished = true
  end

  JSON.dump band_player.to_h
end

get '/bands/:id/session.mid' do |id|
  band = Band.find(id) or pass
  if File.exists?("public/#{id}.mid")
    send_file("public/#{id}.mid")
  elsif band.has_finished
    `./midicat.rb public/#{id}.mid uploads/#{id}-*.mid`
    send_file("public/#{id}.mid")
  else
    halt 204
  end
end
