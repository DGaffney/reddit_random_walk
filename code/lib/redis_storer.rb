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
end