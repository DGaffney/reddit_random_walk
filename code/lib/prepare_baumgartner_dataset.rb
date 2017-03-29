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

  def run
    get_reddit_data
    extract_useful_fields
    sparsify_files
    concatenate_files
  end
end