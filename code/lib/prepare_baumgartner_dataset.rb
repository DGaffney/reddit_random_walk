class BaumgartnerDataset
  include BaumgartnerManifest
  include BaumgartnerDownload
  include BaumgartnerSparsify
  include BaumgartnerConcatenate
  include BaumgartnerSort
  include BaumgartnerTransitions
  attr_accessor :full
  def initialize(full_dataset=false)
    @full = full_dataset
    @method_suffix = "_#{@full ? "real" : "test"}"
  end

  def submission_files
    self.send("submission_files#{@method_suffix}")
  end
  
  def comment_files
    self.send("comment_files#{@method_suffix}")
  end

  def download_and_prepare
    `rm -r #{ENV["PWD"]}/data/baumgartner_*`
    puts "Downloading Data"
    get_reddit_data
    puts "Extracting Useful Fields"
    sparsify_files
    puts "Concatenating into single file"
    concatenate_files
    puts "Sorting data"
    sort_files
    puts "Generating User Transits"
    generate_transitions
  end
  
  def store_sliced_transitions(strftime_str, percentile)
    generate_edge_transitions_by_timeframe(strftime_str, percentile)
    summarize_transitions(strftime_str, percentile)
  end
  
  def analyze_sliced_transitions(strftime_str, percentile)
    cumulative_post_cutoff = RedisStorer.get_json("global_user_counts").values.sort.percentile(percentile.to_f)
    CSV.read(transition_slice_manifest_file(strftime_str)).flatten.each do |file|
      NodeWalkerDiffs.perform_async(file, percentile, strftime_str, cumulative_post_cutoff)
    end
    while Sidekiq::Queue.new("daily_edges_redis").size+Sidekiq::RetrySet.new.size > 0
      sleep(1)
    end
    NodeWalkerDiffs.export(strftime_str, percentile, cumulative_post_cutoff)
  end
end
