module BaumgartnerConcatenate
  def all_activities_file
    "#{ENV["PWD"]}/data/baumgartner_concatenated/all_activities.csv"
  end

  def mkdir_concatenated_folder
    `mkdir #{ENV["PWD"]}/data/baumgartner_concatenated`
  end

  def all_interactions_file
    `#{ENV["PWD"]}/data/baumgartner_sparse/missing`
  end

  def concatenate_sparse_comment(year, month)
    `cat #{sparse_file_comment(year, month)} >> #{all_activities_file}`
  end

  def concatenate_sparse_submission(year, month)
    `cat #{sparse_file_submission(year, month)} >> #{all_activities_file}`
  end

  def concatenate_missing_data
    `cat #{ENV["PWD"]}/data/baumgartner_sparse/missing/comments.csv >> #{all_activities_file}`
    `cat #{ENV["PWD"]}/data/baumgartner_sparse/missing/submissions.csv >> #{all_activities_file}`
  end

  def concatenate_files
    mkdir_concatenated_folder
    self.send("submission_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        concatenate_sparse_submission(year, month)
      end
    end
    self.send("comment_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        concatenate_sparse_comment(year, month)
      end
    end
    if @full
      concatenate_missing_data
    end
  end
end