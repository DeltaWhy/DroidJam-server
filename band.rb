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

  def initialize(hash)
    super(hash)
    @includes = []
  end

  def players
    self.id = SecureRandom.hex(10) if self.id == nil
    BandPlayers.new(self.id)
  end

  def includes(key)
    raise KeyError unless key == :players
    @includes << key
    self
  end

  def save
    self.id = SecureRandom.hex(10) if self.id == nil
    unless self.name
      raise "Band must have a name!"
    end
    $redis.set("band:#{self.id}", JSON.dump(self.to_h))
    self
  end

  def to_h
    merge_hash = {}
    @includes.each do |k|
      v = self.send(k)
      if v.is_a? Enumerable
        v = v.map(&:to_h)
      elsif !v.is_a? Hash
        v = v.to_h
      end
      merge_hash[k] = v
    end
    super.merge(merge_hash)
  end
end
