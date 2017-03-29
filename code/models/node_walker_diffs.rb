class NodeWalkerDiffs
  include MongoMapper::Document
  include Sidekiq::Worker
  sidekiq_options queue: :node_walker_diff
  key :day_str, String
  key :day, Time
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
  
  def self.kickoff
    $all_reddit_days.each do |day|
      NodeWalkerDiffs.perform_async(day)
    end
  end
  
  def perform(day)
    days_probabilities = DailyEdgeRedis.get(day);false
    edge_counts = days_probabilities.values.collect(&:keys).flatten.counts;false
    all_sent_amounts = {}
    days_probabilities.values.each do |value_set|
      value_set.each do |source_subreddit,sent_amount|
        all_sent_amounts[source_subreddit] ||= 0
        all_sent_amounts[source_subreddit] += sent_amount
      end
    end;false
    all_diffs = []
    days_probabilities.keys.each do |subreddit|
      if days_probabilities[subreddit].count == 1 && days_probabilities[subreddit].keys.first == subreddit
        all_diffs << {day_str: day, 
          day: Time.parse(day), 
          subreddit: subreddit, 
          sent_amounts: [],
          sent_percents: [], 
          expected_amounts: [], 
          expected_percents: [], 
          traffic_in_count: 0, 
          edge_count: 0, 
          self_loop_amount: days_probabilities[subreddit][subreddit], 
          self_loop_percent: 1.0, 
          node_error: 0,
          weighted_node_error: 0
        }
      else
        expected_percents = []
        sent_percents = []
        expected_amounts = []
        sent_amounts = []
        traffic_in_count = Hash[days_probabilities[subreddit].reject{|k,v| k == subreddit}].values.sum
        edge_count = Hash[days_probabilities[subreddit].reject{|k,v| k == subreddit}].count
        self_loop_amount = 0
        self_loop_percent = 0.0
        days_probabilities[subreddit].each do |sent_subreddit, sent_count|
          if subreddit != sent_subreddit
            expected_percents << 1/edge_counts[sent_subreddit].to_f
            sent_percents << sent_count.to_f/all_sent_amounts[sent_subreddit]
            expected_amounts << edge_counts[sent_subreddit].to_f
            sent_amounts << sent_count
          else
            self_loop_amount = sent_count
            self_loop_percent = sent_count.to_f/all_sent_amounts[subreddit]
          end
        end
        all_diffs << {day_str: day, 
          day: Time.parse(day), 
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
          weighted_node_error: get_weighted_node_error(expected_percents, sent_amounts, sent_percents, traffic_in_count)
        }
        if all_diffs.count > 20
          NodeWalkerDiffs.collection.insert(all_diffs)
          all_diffs = []
        end
      end
    end
    NodeWalkerDiffs.collection.insert(all_diffs) if !all_diffs.empty?
  end
end
