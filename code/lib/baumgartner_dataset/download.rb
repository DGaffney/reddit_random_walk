module BaumgartnerDownload
  def get(url, folder_dest)
    `wget #{url}`
    file = url.split("/").last
    `mv #{file} #{project_folder}/#{folder_dest}/`
  end

  def get_missing_data(dataset_tag="main")
    return nil if dataset_tag != "main"
    get("http://www.devingaffney.com/files/missing_comments_and_early_missing_submissions.zip", "data/baumgartner/missing_data")
    `unzip #{project_folder}/missing_comments_and_early_missing_submissions.zip`
    `mkdir #{project_folder}/data/baumgartner/missing_data`
    `mv #{project_folder}/missing_comments.json #{project_folder}/data/baumgartner/missing_data/`
    `mv #{project_folder}/missing_subreddits_0-10m.json #{project_folder}/data/baumgartner/missing_data/`
    `rm #{project_folder}/missing_comments_and_early_missing_submissions.zip`
  end

  #TAKE CARE IN DOWNLOADING DATA - too many requests will crash Baumgartner's server.
  def get_reddit_data(dataset_tag="main")
    `mkdir -p #{project_folder}/data/baumgartner/submissions`
    `mkdir -p #{project_folder}/data/baumgartner/comments`
    submission_files(dataset_tag).each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/submissions/RS_#{year}-#{month}.bz2", "data/baumgartner/submissions")
      end
    end
    comment_files(dataset_tag).each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/comments/RC_#{year}-#{month}.bz2", "data/baumgartner/comments")
      end
    end
    if @full
      get_missing_data(dataset_tag)
    end
  end
end