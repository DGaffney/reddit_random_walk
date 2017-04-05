class BaumgartnerDataset
  include BaumgartnerManifest
  include BaumgartnerDownload
  include BaumgartnerSparsify
  include BaumgartnerConcatenate
  include BaumgartnerSort
  include BaumgartnerTransitions
  attr_accessor :full, :downloaded, :dataset_tag
  def initialize(dataset_tag="full")
    @method_suffix = "_#{dataset_tag}"
    @dataset_tag = dataset_tag
    `mkdir #{ENV["PWD"]}/results`
    `mkdir #{project_folder}`
  end

  def project_folder
    "#{ENV["PWD"]}/results/dataset#{@method_suffix}/"
  end

  def submission_files(dataset_tag)
    self.send("submission_files#{@method_suffix}")
  end
  
  def comment_files(dataset_tag)
    self.send("comment_files#{@method_suffix}")
  end

  def download
    `rm -r #{project_folder}baumgartner_*`
    puts "Downloading Data"
    get_reddit_data
  end

  def prepare
    puts "Extracting Useful Fields"
    sparsify_files
    puts "Concatenating into single file"
    concatenate_files
    puts "Sorting data"
    sort_files
    puts "Generating User Transits"
    generate_transitions
  end

  def download_and_prepare
    download if @downloaded
    prepare
  end
  
  def store_sliced_transitions(strftime_str, percentile, only_higher=true)
    generate_edge_transitions_by_timeframe(strftime_str)
    summarize_transitions(strftime_str, percentile, only_higher)
  end
  
  def analyze_sliced_transitions(strftime_str, percentile)
    cumulative_post_cutoff = RedisStorer.get_json("global_user_counts#{@method_suffix}").values.sort.percentile(percentile.to_f)
    CSV.read(transition_slice_manifest_file(strftime_str)).flatten.each do |file|
      NodeWalkerDiffs.perform_async(@method_suffix, file, percentile, strftime_str, cumulative_post_cutoff)
    end
    while Sidekiq::Queue.new("daily_edges_redis").size+Sidekiq::RetrySet.new.size > 0
      sleep(1)
    end
    NodeWalkerDiffs.export(project_folder, strftime_str, percentile, cumulative_post_cutoff)
  end
end
