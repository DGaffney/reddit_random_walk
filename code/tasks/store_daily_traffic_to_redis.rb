class StoreDailyTrafficToRedis
  include Sidekiq::Worker
  sidekiq_options queue: :daily_edges_redis
  def perform(dataset_tag, file, strftime_str, cumulative_post_cutoff, percentile, only_higher)
    user_counts = RedisStorer.get_json("global_user_counts#{dataset_tag}")
    counts = {}
    CSV.foreach(BaumgartnerDataset.new(dataset_tag.split("")[1..-1].join("")).time_transitions+"/"+file) do |row|
    if only_higher
      if user_counts[row.last] >= cumulative_post_cutoff
        counts[row[1]] ||= {}
        counts[row[1]][row.first] ||= 0
        counts[row[1]][row.first] += 1
      end
    else
      if user_counts[row.last] <= cumulative_post_cutoff
        counts[row[1]] ||= {}
        counts[row[1]][row.first] ||= 0
        counts[row[1]][row.first] += 1
      end
    end
    end
    current_i = 0
    counts.each do |target_subreddit, source_subreddits|
      source_subreddits.each_slice(500) do |source_subreddit_slice|
        RedisStorer.new.hash_set("#{only_higher == true ? "higher" : "lower"}#{dataset_tag}_#{file}_#{strftime_str}_#{percentile}:#{current_i}",[target_subreddit, source_subreddit_slice].flatten.join(","))
        current_i += 1
      end
    end
  end
end