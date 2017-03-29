class StoreDailyTrafficToRedis
  include Sidekiq::Worker
  sidekiq_options queue: :daily_edges_redis
  def perform(day)
    puts day
    count_data = DailyEdge.get_by_day_str(day)["count_data"]
    transformed = {}
    count_data.each do |subreddits, count|
      transformed[subreddits.last] ||= []
      transformed[subreddits.last] << [subreddits.first, count]
    end
    current_i = 0
    transformed.each do |target_subreddit, source_subreddits|
      source_subreddits.each_slice(500) do |source_subreddit_slice|
        RedisStorer.new.hash_set("#{day}:#{current_i}",[target_subreddit, source_subreddit_slice].flatten.join(","))
        current_i += 1
      end
    end
  end
end
