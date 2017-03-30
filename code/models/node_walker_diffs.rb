class NodeWalkerDiffs
  include MongoMapper::Document
  include Sidekiq::Worker
  sidekiq_options queue: :daily_edges_redis
  key :time_str, String
  key :time, Time
  key :subreddit, String
  key :sent_amounts, Array
  key :sent_percents, Array
  key :expected_amounts, Array
  key :expected_percents, Array
  key :traffic_in_count, Integer
  key :edge_count, Integer
  key :self_loop_amount, Integer
  key :self_loop_percent, Float
  key :node_error, Float
  key :weighted_node_error, Float
  key :percentile, Float
  key :strftime_str, String
  key :cumulative_post_cutoff, Integer
  key :attributable_to_random, Float
  key :walks_attributed_to_random, Integer
  key :walks_not_attributed_to_random, Integer
  def get_node_error(expected_percents, sent_percents, edge_count)
    get_node_error_dist(expected_percents, sent_percents).sum/edge_count
  end

  def get_weighted_node_error(expected_percents, sent_amounts, sent_percents, traffic_in_count)
    get_weighted_node_error_dist(expected_percents, sent_amounts, sent_percents).sum/traffic_in_count
  end

  def get_node_error_dist(expected_percents, sent_percents)
    expected_percents.zip(sent_percents).collect{|x| Math.sqrt((x[0]-x[1])**2)}
  end

  def get_weighted_node_error_dist(expected_percents, sent_amounts, sent_percents)
    dist = []
    expected_percents.each_with_index do |pct, i|
      dist << sent_amounts[i]*Math.sqrt((pct-sent_percents[i])**2)
    end
    return dist
  end

  def self.kickoff(strftime_str, percentile, cumulative_post_cutoff)
    CSV.read(BaumgartnerDataset.new.transition_slice_manifest_file(strftime_str)).each do |time|
      NodeWalkerDiffs.perform_async(time, percentile, strftime_str, cumulative_post_cutoff)
    end
  end

  def self.export(strftime_str, percentile, cumulative_post_cutoff)
    sequential = CSV.open(ENV["PWD"]+"/error_diffs_#{strftime_str}_#{percentile}_sequential.csv", "w")
    summarized = CSV.open(ENV["PWD"]+"/error_diffs_#{strftime_str}_#{percentile}_summarized.csv", "w")
    sequential << ["Subreddit", "Time Slice", "Inbound Traffic Count", "Abs Error from Random", "Percent Attributable to Random"]
    summarized << ["Subreddit", "Sum Inbound Traffic Count", "Obs Count", "Avg Abs Error from Random", "Avg Percent Attributable to Random"]
    summary_data = {}
    NodeWalkerDiffs.where(strftime_str: strftime_str, percentile: percentile, cumulative_post_cutoff: cumulative_post_cutoff).order(:time).each do |nwd|
      sequential << [nwd.subreddit, nwd.time_str, nwd.traffic_in_count, nwd.node_error, nwd.attributable_to_random]
      summary_data[nwd.subreddit] ||= {subreddit_size: 0, total_obs: 0, total_error: 0, total_attributable: 0}
      summary_data[nwd.subreddit][:subreddit_size] += nwd.traffic_in_count
      summary_data[nwd.subreddit][:total_obs] += 1
      summary_data[nwd.subreddit][:total_error] += nwd.node_error
      summary_data[nwd.subreddit][:total_attributable] += nwd.attributable_to_random
    end;false
    sequential.close
    summary_data.each do |subreddit, sub_data|
      summarized << [subreddit, sub_data[:subreddit_size], sub_data[:total_obs], sub_data[:total_error].to_f/sub_data[:total_obs], sub_data[:total_attributable].to_f/sub_data[:total_obs]]
    end;false
    summarized.close
  end

  def perform(time, percentile, strftime_str, cumulative_post_cutoff)
    times_probabilities = DailyEdgeRedis.get(time, strftime_str, percentile)
    edge_counts = times_probabilities.values.collect(&:keys).flatten.counts
    all_sent_amounts = {}
    times_probabilities.values.each do |value_set|
      value_set.each do |source_subreddit,sent_amount|
        all_sent_amounts[source_subreddit] ||= 0
        all_sent_amounts[source_subreddit] += sent_amount
      end
    end;false
    all_diffs = []
    times_probabilities.keys.each do |subreddit|
      if !(times_probabilities[subreddit].count == 1 && times_probabilities[subreddit].keys.first == subreddit)
      #here I removed code for accurately assessing subreddits that transfer no users as 0 values - this may still be a valid stat to calculate though.
        expected_percents = []
        sent_percents = []
        expected_amounts = []
        sent_amounts = []
        traffic_in_count = Hash[times_probabilities[subreddit].reject{|k,_| k == subreddit}].values.sum
        edge_count = Hash[times_probabilities[subreddit].reject{|k,_| k == subreddit}].size
        self_loop_amount = 0
        self_loop_percent = 0.0
        times_probabilities[subreddit].each do |sent_subreddit, sent_count|
          if subreddit != sent_subreddit
            expected_percents << 1/edge_counts[sent_subreddit].to_f
            sent_percents << sent_count.to_f/all_sent_amounts[sent_subreddit]
            expected_amounts << edge_counts[sent_subreddit].to_f
            sent_amounts << sent_count
          else
            self_loop_amount = sent_count
            self_loop_percent = sent_count.to_f/all_sent_amounts[subreddit]
          end
        end;false
        all_diffs << {time_str: time, 
          time: Time.parse(time), 
          subreddit: subreddit, 
          sent_amounts: sent_amounts, 
          sent_percents: sent_percents, 
          expected_amounts: expected_amounts, 
          expected_percents: expected_percents, 
          traffic_in_count: traffic_in_count, 
          edge_count: edge_count, 
          self_loop_amount: self_loop_amount, 
          self_loop_percent: self_loop_percent, 
          node_error: get_node_error(expected_percents, sent_percents, edge_count),
          weighted_node_error: get_weighted_node_error(expected_percents, sent_amounts, sent_percents, traffic_in_count),
          percentile: percentile,
          strftime_str: strftime_str,
          cumulative_post_cutoff: cumulative_post_cutoff
        }
        diff_percents = all_diffs[-1][:expected_percents].zip(all_diffs[-1][:sent_percents]).collect{|x| Math.sqrt((x[0]-x[1])**2)}
        not_attributable_to_random = []
        totals = []
        diff_percents.each_with_index do |val, i|
          not_attributable_to_random << all_diffs[-1][:sent_amounts][i]*val
          totals << all_diffs[-1][:sent_amounts][i]
        end
        all_diffs[-1][:attributable_to_random] = (totals.sum-not_attributable_to_random.sum)/totals.sum
        all_diffs[-1][:walks_attributed_to_random] = totals.sum-not_attributable_to_random.sum
        all_diffs[-1][:walks_not_attributed_to_random] = not_attributable_to_random.sum
        if all_diffs.count > 20
          NodeWalkerDiffs.collection.insert(all_diffs)
          all_diffs = []
        end
      end
    end
    NodeWalkerDiffs.collection.insert(all_diffs) if !all_diffs.empty?
  end
end
