require 'ostruct'
require 'securerandom'
require 'redis'
require 'json'

class Band < OpenStruct
  def self.find(id)
    if json = $redis.get("band:#{id}")
      self.new(JSON.parse(json))
    else
      nil
    end
  end

  def self.destroy(id)
    $redis.del("band:#{id}")
  end

  def self.destroy_all
    keys = $redis.keys("band:*")
    keys.each {|key| $redis.del key }
  end

  def self.all
    keys = $redis.keys("band:*")
    keys.map{|key| self.new(JSON.parse($redis.get(key)))}
  end

  def players
    self.id = SecureRandom.hex(10) if self.id == nil
    BandPlayers.new(self.id)
  end

  def save
    self.id = SecureRandom.hex(10) if self.id == nil
    unless self.name
      raise "Band must have a name!"
    end
    $redis.set("band:#{self.id}", JSON.dump(self.to_h))
    self
  end
end
