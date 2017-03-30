class RedisStorer
  def hash_get_key_field(key)
    s = key.split(":")
    {:key => s[0]+":", :field => s[1]}
  end

  def hash_set(key,value)
    kf = hash_get_key_field(key)
    $redis.hset(kf[:key],kf[:field],value)
  end

  def hash_get(key)
    kf = hash_get_key_field(key)
    $redis.hget(kf[:key],kf[:field])
  end
  
  def self.set_json(key, value)
    $redis.set(key, value.to_json)
  end

  def self.get_json(key)
    JSON.parse($redis.get(key))
  end
  
  def self.get_current_db_location
    redis_settings = `redis-cli CONFIG GET \\\*`.split("\n")
    redis_settings[redis_settings.index("dir")+1]+"/"+redis_settings[redis_settings.index("dbfilename")+1]
  end
end