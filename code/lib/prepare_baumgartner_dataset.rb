class PrepareBaumgartnerDataset
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
end
PrepareBaumgartnerDataset.new.generate_transitions