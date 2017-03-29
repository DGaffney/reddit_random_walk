module BaumgartnerDownload
  def get(url, folder_dest)
    `wget #{url}`
    file = url.split("/").last
    `mv #{file} #{ENV["PWD"]}/#{file}`
  end

  def get_missing_submissions
    get("http://files.pushshift.io/reddit/requests/1-10m_submissions.zip", "data/baumgartner/missing_data")
    `unzip #{ENV["PWD"]}/data/baumgartner/missing_data/1-10m_submissions.zip`
    `mv #{ENV["PWD"]}/RS_* #{ENV["PWD"]}/data/baumgartner/missing_data`
    `rm #{ENV["PWD"]}/RS_* #{ENV["PWD"]}/data/baumgartner/missing_data/1-10m_submissions.zip`
  end

  def get_missing_comments
    get("http://www.devingaffney.com/files/reddit_missing_comments_to_feb_2016.json", "data/baumgartner/missing_data")
  end

  #TAKE CARE IN DOWNLOADING DATA - too many requests will crash Baumgartner's server.
  def get_reddit_data
    self.send("submission_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/submissions/RS_#{year}-#{month}.bz2", "data/baumgartner/submissions")
      end
    end
    self.send("comment_files#{@method_suffix}").each do |year, months|
      months.each do |month|
        get("http://files.pushshift.io/reddit/comments/RC_#{year}-#{month}.bz2", "data/baumgartner/comments")
      end
    end
    if @full
      get_missing_submissions
      get_missing_comments
    end
  end
end