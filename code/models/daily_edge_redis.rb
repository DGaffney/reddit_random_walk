class DailyEdgeRedis
  def self.get(dataset_tag, time_slice_str, strftime_str, percentile)
    current_i = 0
    raw = []
    latest = $redis.hget("#{dataset_tag}_#{time_slice_str}_#{strftime_str}_#{percentile}:", current_i.to_s)
    while !latest.nil?
      raw << latest.split(",")
      current_i += 1
      latest = $redis.hget("#{dataset_tag}_#{time_slice_str}_#{strftime_str}_#{percentile}:", current_i.to_s)
    end
    refreshed = {}
    raw.each do |raw_page|
      refreshed[raw_page.first] ||= {}
      raw_page[1..-1].each_slice(2) do |source_subreddit, inbound_count|
        refreshed[raw_page.first][source_subreddit] = inbound_count.to_i
      end
    end
    refreshed
  end
end