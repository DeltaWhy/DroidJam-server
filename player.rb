require 'ostruct'
require 'securerandom'
require 'redis'
require 'json'

class Player < OpenStruct
  def self.find(id)
    if json = $redis.get("player:#{id}")
      self.new(JSON.parse(json))
    else
      nil
    end
  end

  def self.destroy(id)
    $redis.del("player:#{id}")
  end

  def self.destroy_all
    keys = $redis.keys("player:*")
    keys.each {|key| $redis.del key }
  end

  def self.all
    keys = $redis.keys("player:*")
    keys.map{|key| self.new(JSON.parse($redis.get(key)))}
  end

  def save
    self.id = SecureRandom.hex(10) if self.id == nil
    unless self.name
      raise "Player must have a name!"
    end
    $redis.set("player:#{self.id}", JSON.dump(self.to_h))
    self
  end
end
