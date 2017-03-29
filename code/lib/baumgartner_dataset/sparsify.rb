module BaumgartnerSparsify
  def mkdir_sparse_folders
    `mkdir #{ENV["PWD"]}/data/baumgartner_sparse/`
    `mkdir #{ENV["PWD"]}/data/baumgartner_sparse/submissions`
    `mkdir #{ENV["PWD"]}/data/baumgartner_sparse/comments`
    `mkdir #{ENV["PWD"]}/data/baumgartner_sparse/missing`
  end

  def sort_file
    "LC_ALL=C sort -t, -k1"
  end

  def bzip_submission(year, month)
    "bzip2 -dck #{ENV["PWD"]}/data/baumgartner/submissions/#{year}/RS_#{year}-#{month}.bz2"
  end

  def jq_submission
    "jq '. | [(.created_utc | tostring), .subreddit, .author, \"t3_\"+.id] | join(\",\")' | tr -d '\"'"
  end

  def sparse_file_submission(year, month)
    "#{ENV["PWD"]}/data/baumgartner_sparse/submissions/submission_sparse_#{year}-#{month}.csv"
  end

  def sparsify_submission(year, month)
    `#{bzip_submission(year, month)} | #{jq_submission} | #{sort_file} >> #{sparse_file_submission(year, month)}`
  end

  def bzip_comment(year, month)
    "bzip2 -dck #{ENV["PWD"]}/data/baumgartner/submissions/#{year}/RC_#{year}-#{month}.bz2"
  end

  def jq_comment
    "jq '. | [(.created_utc | tostring), .subreddit, .author, \"t1_\"+.id, .parent_id] | join(\",\")' | tr -d '\"'"
  end

  def sparse_file_comment(year, month)
    "#{ENV["PWD"]}/data/baumgartner_sparse/comment/comment_sparse_#{year}-#{month}.csv"
  end

  def sparsify_comment(year, month)
    `#{bzip_comment(year, month)} | #{jq_comment} | #{sort_file} >> #{sparse_file_comment(year, month)}`
  end

  def sparsify_missing_data
    `cat #{ENV["PWD"]}/data/baumgartner/missing_data/missing_comments.json | #{jq_comment} | #{sort_file} >> #{ENV["PWD"]}/data/baumgartner_sparse/missing/comments.csv`
    `cat #{ENV["PWD"]}/data/baumgartner/missing_data/missing_subreddits_0-10m.json | #{jq_submission} | #{sort_file} >> #{ENV["PWD"]}/data/baumgartner_sparse/missing/submissions.csv`
  end

  def sparsify_files
    mkdir_sparse_folders
    self.send("submission_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        sparsify_submission(year, month)
      end
    end
    self.send("comment_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        sparsify_comment(year, month)
      end
    end
    if @full
      sparsify_missing_data
    end
  end
end