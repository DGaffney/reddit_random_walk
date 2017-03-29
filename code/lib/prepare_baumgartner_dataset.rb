class PrepareBaumgartnerDataset
  include BaumgartnerManifest
  include BaumgartnerDownload
  include BaumgartnerSparsify
  include BaumgartnerConcatenate
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
  def run
    get_reddit_data
    extract_useful_fields
    sparsify_files
    concatenate_files
    
  end
end