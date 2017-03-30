module BaumgartnerDownload
  def get(url, folder_dest)
    `wget #{url}`
    file = url.split("/").last
    `mv #{file} #{ENV["PWD"]}/#{folder_dest}/`
  end

  def get_missing_data
    get("http://www.devingaffney.com/files/missing_comments_and_early_missing_submissions.zip", "data/baumgartner/missing_data")
    `unzip #{ENV["PWD"]}/data/baumgartner/missing_data/missing_comments_and_early_missing_submissions.zip`
    `mv #{ENV["PWD"]}/missing_comments.json #{ENV["PWD"]}/data/baumgartner/missing_data`
    `mv #{ENV["PWD"]}/missing_subreddits_0-10m.json #{ENV["PWD"]}/data/baumgartner/missing_data`
    `rm #{ENV["PWD"]}/data/baumgartner/missing_data/missing_comments_and_early_missing_submissions.zip`
  end

  #TAKE CARE IN DOWNLOADING DATA - too many requests will crash Baumgartner's server.
  def get_reddit_data
    `mkdir -p #{ENV["PWD"]}/data/baumgartner/submissions`
    `mkdir -p #{ENV["PWD"]}/data/baumgartner/comments`
    submission_files.each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/submissions/RS_#{year}-#{month}.bz2", "data/baumgartner/submissions")
      end
    end
    comment_files.each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/comments/RC_#{year}-#{month}.bz2", "data/baumgartner/comments")
      end
    end
    if @full
      get_missing_data
    end
  end
end