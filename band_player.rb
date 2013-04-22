require 'ostruct'
require 'securerandom'
require 'redis'
require 'json'

class BandPlayers
  include Enumerable

  def initialize(band_id)
    @band_id = band_id
    fetch_players
  end

  def find(id)
    @store.find{|p| p.id == id}
  end

  def create(hash)
    BandPlayer.new(hash.merge({band_id: @band_id})).save
  end

  def destroy(id)
    $redis.del("band:#@band_id:player:#{id}")
    @store.delete_if{|p| p.id == id}
  end

  def destroy_all
    keys = $redis.keys("band:#@band_id:player:*")
    keys.each{|key| $redis.del(key)}
  end

  def each(*args, &block)
    @store.each(*args, &block)
  end

  private
  def fetch_players
    keys = $redis.keys("band:#@band_id:player:*")
    @store = keys.map{|key| BandPlayer.new(JSON.parse($redis.get(key)).merge({band_id: @band_id}))}
  end
end

class BandPlayer < OpenStruct
  def initialize(hash)
    super(hash)
    unless self.band_id
      raise "BandPlayer must have a band_id!"
    end
  end

  def save
    self.id = SecureRandom.hex(10) if self.id == nil
    unless self.name
      raise "Band must have a name!"
    end
    $redis.set("band:#{self.band_id}:player:#{self.id}", JSON.dump(self.to_h))
    self
  end
end
