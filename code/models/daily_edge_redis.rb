class DailyEdgeRedis
  def self.get(day)
    current_i = 0
    raw = []
    latest = $redis.hget(day+":", current_i.to_s)
    while !latest.nil?
      raw << latest.split(",")
      current_i += 1
      latest = $redis.hget(day+":", current_i.to_s)
    end
    refreshed = {}
    raw.each do |raw_page|
      refreshed[raw_page.first] ||= {}
      raw_page[1..-1].each_slice(2) do |source_subreddit, inbound_count|
        refreshed[raw_page.first][source_subreddit] = inbound_count.to_i
      end
    end;false
    refreshed
  end
  def self.get_range(start_day, end_day)
    start_time = Time.parse(Time.parse(start_day.to_s).strftime("%Y-%m-%d 00:00:00"))
    end_time = Time.parse(Time.parse(end_day.to_s).strftime("%Y-%m-%d 00:00:00"))
    cur_time = start_time
    full_refreshed = {}
    while cur_time < end_time
      day_data = DailyEdgeRedis.get(cur_time.strftime("%Y-%m-%d"))
      day_data.each do |target_subreddit, source_subreddits|
        full_refreshed[target_subreddit] ||= {}
        source_subreddits.each do |source_subreddit,count|
          full_refreshed[target_subreddit][source_subreddit] ||= 0
          full_refreshed[target_subreddit][source_subreddit] += count
        end
      end
      cur_time += 24*60*60
    end
    return full_refreshed
  end
end