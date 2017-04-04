module BaumgartnerSort
  def all_activities_file_time_sorted
    "#{project_folder}/data/baumgartner_concatenated/all_activities_sorted_time.csv"
  end

  def all_activities_file_author_time_sorted
    "#{project_folder}/data/baumgartner_concatenated/all_activities_sorted_author_time.csv"
  end

  def sort_files
    `mkdir #{project_folder}/tmp`
    `LC_ALL=C sort -nrt',' -k1,1n -T #{project_folder}/tmp #{all_activities_file} > #{all_activities_file_time_sorted}`
    `LC_ALL=C sort -t',' -k3,3 -k1,1n -T #{project_folder}/tmp #{all_activities_file} > #{all_activities_file_author_time_sorted}`
  end
end