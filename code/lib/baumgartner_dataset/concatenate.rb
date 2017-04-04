module BaumgartnerConcatenate
  def all_activities_file
    "#{project_folder}/data/baumgartner_concatenated/all_activities.csv"
  end

  def mkdir_concatenated_folder
    `mkdir #{project_folder}/data/baumgartner_concatenated`
  end

  def all_interactions_file
    `#{project_folder}/data/baumgartner_sparse/missing`
  end

  def concatenate_sparse_comment(year, month)
    `cat #{sparse_file_comment(year, month)} >> #{all_activities_file}`
  end

  def concatenate_sparse_submission(year, month)
    `cat #{sparse_file_submission(year, month)} >> #{all_activities_file}`
  end

  def concatenate_missing_data
    `cat #{project_folder}/data/baumgartner_sparse/missing/comments.csv >> #{all_activities_file}`
    `cat #{project_folder}/data/baumgartner_sparse/missing/submissions.csv >> #{all_activities_file}`
  end

  def concatenate_files
    mkdir_concatenated_folder
    submission_files(@dataset_tag).each do |year, months|
      months.each do |month|
        concatenate_sparse_submission(year, month)
      end
    end
    comment_files(@dataset_tag).each do |year, months|
      months.each do |month|
        concatenate_sparse_comment(year, month)
      end
    end
    if @full
      concatenate_missing_data
    end
  end
end