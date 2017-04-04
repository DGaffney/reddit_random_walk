#depends on active redis connection with traffic counts for each day from reddit
load 'environment.rb'
class WriteNetworks
  def quarter(month)
    (((3-(month%3))%3)+month)/3
  end

  def topics
    ["business", "gaming", "general", "health", "humor", "images", "meta", "movies", "music", "news", "philosophy", "politics", "questions", "random", "relationships", "science", "sports", "technology"]
  end

  def default_subreddits
    {"AskReddit"=>1, "Economics"=>0, "Health"=>0, "Libertarian"=>0, "Marijuana"=>0, "MensRights"=>0, "Music"=>1, "WTF"=>1, "apple"=>0, "atheism"=>1, "bestof"=>1, "business"=>0, "canada"=>0, "comics"=>0, "conspiracy"=>0, "economy"=>0, "energy"=>0, "entertainment"=>0, "environment"=>0, "food"=>1, "funny"=>1, "gadgets"=>1, "gaming"=>1, "geek"=>0, "gossip"=>0, "humor"=>0, "it"=>0, "linux"=>0, "math"=>0, "movies"=>1, "news"=>1, "nsfw"=>0, "obama"=>0, "offbeat"=>0, "philosophy"=>1, "pics"=>1, "politics"=>1, "programming"=>0, "reddit.com"=>1, "science"=>1, "scifi"=>0, "self"=>0, "sex"=>0, "sports"=>1, "technology"=>1, "videos"=>1, "web_design"=>0, "wikipedia"=>0, "worldnews"=>1, "worldpolitics"=>0}
  end

  def categorized_subreddits
    {"AskReddit"=>12, "Economics"=>0, "Health"=>3, "Libertarian"=>11, "Marijuana"=>3, "MensRights"=>11, "Music"=>8, "WTF"=>13, "apple"=>17, "atheism"=>10, "bestof"=>6, "business"=>0, "canada"=>2, "comics"=>5, "conspiracy"=>11, "economy"=>11, "energy"=>17, "entertainment"=>2, "environment"=>11, "food"=>3, "funny"=>4, "gadgets"=>17, "gaming"=>1, "geek"=>13, "gossip"=>2, "humor"=>4, "it"=>2, "linux"=>17, "math"=>15, "movies"=>7, "news"=>9, "nsfw"=>2, "obama"=>11, "offbeat"=>9, "philosophy"=>10, "pics"=>5, "politics"=>11, "programming"=>17, "reddit.com"=>2, "science"=>15, "scifi"=>7, "self"=>2, "sex"=>14, "sports"=>16, "technology"=>17, "videos"=>2, "web_design"=>17, "wikipedia"=>2, "worldnews"=>9, "worldpolitics"=>11}
  end

  def political_subreddits
    Hash[categorized_subreddits.collect{|k,v| [k, v == topics.index("politics") ? 1 : 0]}]
  end

  def technology_subreddits
    Hash[categorized_subreddits.collect{|k,v| [k, v == topics.index("technology") ? 1 : 0]}]
  end
  
  def general_subreddits
    Hash[categorized_subreddits.collect{|k,v| [k, v == topics.index("general") ? 1 : 0]}]
  end

  def default_status
    {"AskReddit"=>1, "Economics"=>0, "Health"=>0, "Libertarian"=>0, "Marijuana"=>0, "MensRights"=>0, "Music"=>1, "WTF"=>1, "apple"=>0, "atheism"=>1, "bestof"=>1, "business"=>0, "canada"=>0, "comics"=>0, "conspiracy"=>0, "economy"=>0, "energy"=>0, "entertainment"=>0, "environment"=>0, "food"=>1, "funny"=>1, "gadgets"=>1, "gaming"=>1, "geek"=>0, "gossip"=>0, "humor"=>0, "it"=>0, "linux"=>0, "math"=>0, "movies"=>1, "news"=>1, "nsfw"=>0, "obama"=>0, "offbeat"=>0, "philosophy"=>1, "pics"=>1, "politics"=>1, "programming"=>0, "reddit.com"=>1, "science"=>1, "scifi"=>0, "self"=>0, "sex"=>0, "sports"=>1, "technology"=>1, "videos"=>1, "web_design"=>0, "wikipedia"=>0, "worldnews"=>1, "worldpolitics"=>0}
  end

  def time_key(time, type)
    if type == "day"
      return time.strftime("%Y-%m-%d")
    elsif type == "week"
      return time.strftime("%Y-%W")
    elsif type == "month"
      return time.strftime("%Y-%m")
    elsif type == "quarter"
      return time.year.to_s+"-"+quarter(time.month).to_s
    end
  end
  
  def generate_restricted_dataset(time_resolution, edge_cut_percentile=0.0, start_time=Time.parse("2005-06-25"), end_time=Time.parse("2009-06-25"))
    dataset = {}
    all_counts = {}
    first_seens = {}
    traffic_per_step = {}
    time = start_time
    while time < end_time
      data = DailyEdgeRedis.get(time.strftime("%Y-%m-%d"))
      time_str = time_key(time, time_resolution)
      dataset[time_str] ||= {}
      data.each do |target_node, source_nodes|
        first_seens[target_node] = time_str if first_seens[target_node].nil?
        traffic_per_step[target_node] ||= {}
        traffic_per_step[target_node][time_str] = data.values.collect{|x| x[target_node]}.compact.sum
        source_nodes.each do |source_node, traffic_count|
          dataset[time_str][target_node] ||= {}
          dataset[time_str][target_node][source_node] ||= 0
          dataset[time_str][target_node][source_node] += traffic_count
          all_counts[target_node] ||= 0
          all_counts[target_node] += traffic_count
        end
      end
      time = time+24*60*60
    end;false
    transits_accounted = all_counts.sort_by{|k,v| v}.reverse.first(50).collect(&:last).sum
    transits_not_accounted = all_counts.sort_by{|k,v| v}.reverse[50..-1].collect(&:last).sum
    puts transits_accounted/(transits_accounted+transits_not_accounted)
    earliest_possible_date = all_counts.sort_by{|k,v| v}.reverse.first(50).collect(&:first).collect{|x| first_seens[x]}.sort.last
    all_names = (dataset.values.collect(&:keys).flatten|dataset.values.collect(&:values).collect{|x| x.collect(&:keys)}.flatten).uniq;false
    biggest_subreddits = all_counts.sort_by{|k,v| v}.reverse.first(50).collect(&:first)
    restricted = {}
    dataset.each do |time_step, node_data|
      restricted[time_step] ||= {}
      node_data.each do |target_node, source_nodes|
        next if !biggest_subreddits.include?(target_node)
        restricted[time_step][target_node] ||= {}
        source_nodes.each do |source_node, inbound_count|
          restricted[time_step][target_node][source_node] = inbound_count if source_node != target_node && biggest_subreddits.include?(source_node)
        end
      end
    end;false
    dataset = restricted;false
    #obs_est_data = CSV.open("blah.csv", "w")
    dataset.keys.sort[(dataset.keys.sort.index(earliest_possible_date)+1)..-1].each do |time_step|
      network = dataset[time_step]
      cutoff_count = network.values.collect(&:values).flatten.sort.percentile(edge_cut_percentile)
      cutoff_net = {}
      network.each do |target_node, source_nodes|
        cutoff_net[target_node] ||= {}
        source_nodes.each do |source_node, source_val|
          if source_val >= cutoff_count
            cutoff_net[target_node][source_node] = source_val
          end
        end
      end
      network = cutoff_net;false
      f = File.open("tergm_analysis/"+time_step+"_#{time_resolution}_#{edge_cut_percentile}.csv", "w")
      n = File.open("tergm_analysis_node_data/"+time_step+"_#{time_resolution}_#{edge_cut_percentile}.csv", "w")
      f.write(["source", "target", "observed", "previous", "estimated"].join(",")+"\n")
      n.write(["subreddit", "default_status", "traffic_count", "log_traffic_count", "category", "political", "general_interest", "technology"].join(",")+"\n")
      network.keys.sort.each do |target_node|
        next if target_node.nil? || target_node.empty?
        observed_traffic = network[target_node]
        previous_observed_traffic = dataset[dataset.keys.sort[(dataset.keys.sort.index(time_step)-1)]][target_node] || {}
        estimated_traffic = Hash[observed_traffic.keys.collect{|k| [k, (1.0/network.collect{|kk,v| v[k]}.count) * network.collect{|kk,v| v[k]}.sum]}]
        #estimated_traffic.collect{|k,v| obs_est_data << [v, observed_traffic[k]]}
        if biggest_subreddits.include?(target_node)
          n.write([target_node, default_status[target_node], traffic_per_step[target_node][time_step], (Math.log(traffic_per_step[target_node][time_step]).to_i rescue 0), categorized_subreddits[target_node], political_subreddits[target_node], general_subreddits[target_node], technology_subreddits[target_node]].join(",")+"\n")
        end
        observed_traffic.keys.each do |source_node, traffic_count|
          if target_node != source_node && biggest_subreddits.include?(source_node) && biggest_subreddits.include?(target_node)
              f.write([source_node, target_node, observed_traffic[source_node], previous_observed_traffic[source_node].to_i, estimated_traffic[source_node].to_i].join(",")+"\n")
          end
        end
      end
      f.close
      n.close
    end;false
    `python generate_gml.py #{time_resolution}`
    #obs_est_data.close
  end
  
  def self.kickoff
    #0.9353927979847418
    BaumgartnerDataset.new("early_reddit").download
    BaumgartnerDataset.new("early_reddit").prepare
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m-%d", 0.0)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m-%d", 0.0)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m-%d", 0.25)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m-%d", 0.25)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m-%d", 0.50)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m-%d", 0.50)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m-%d", 0.75)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m-%d", 0.75)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m", 0.0)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m", 0.0)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m", 0.25)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m", 0.25)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m", 0.50)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m", 0.50)
    BaumgartnerDataset.new("early_reddit").store_sliced_transitions("%Y-%m", 0.75)
    BaumgartnerDataset.new("early_reddit").analyze_sliced_transitions("%Y-%m", 0.75)
    WriteNetworks.new.generate_restricted_dataset("day")
    WriteNetworks.new.generate_restricted_dataset("week")
    WriteNetworks.new.generate_restricted_dataset("month")
    WriteNetworks.new.generate_restricted_dataset("quarter")
    WriteNetworks.new.generate_restricted_dataset("day", 0.25)
    WriteNetworks.new.generate_restricted_dataset("week", 0.25)
    WriteNetworks.new.generate_restricted_dataset("month", 0.25)
    WriteNetworks.new.generate_restricted_dataset("quarter", 0.25)
    WriteNetworks.new.generate_restricted_dataset("day", 0.5)
    WriteNetworks.new.generate_restricted_dataset("week", 0.5)
    WriteNetworks.new.generate_restricted_dataset("month", 0.5)
    WriteNetworks.new.generate_restricted_dataset("quarter", 0.5)
    WriteNetworks.new.generate_restricted_dataset("day", 0.75)
    WriteNetworks.new.generate_restricted_dataset("week", 0.75)
    WriteNetworks.new.generate_restricted_dataset("month", 0.75)
    WriteNetworks.new.generate_restricted_dataset("quarter", 0.75)
    WriteNetworks.new.generate_restricted_dataset("day", 0.95)
    WriteNetworks.new.generate_restricted_dataset("week", 0.95)
    WriteNetworks.new.generate_restricted_dataset("month", 0.95)
    WriteNetworks.new.generate_restricted_dataset("quarter", 0.95)
  end
end