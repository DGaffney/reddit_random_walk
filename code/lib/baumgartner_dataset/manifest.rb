module BaumgartnerManifest
  def all_months
    "01".upto("12").to_a
  end

  def full_timeline
    res = {"2016" => ["01", "02"]}
    "2008".upto("2015").collect{|y| res[y] = all_months}
    res
  end

  def submission_files_full
    full_timeline.merge({"2006" => ["01", "02", "03", "04", "05", "06", "07"], "2007" => ["01", "02", "03", "06", "07", "10", "11", "12"]})
  end

  def submission_files_test
    {
      "2006" => ["01", "02"]
    }
  end

  def submission_files_early_reddit
    {"2008" => ["04", "05", "06", "07", "08", "09", "10", "11", "12"], "2009" => ["01", "02", "03", "04", "05", "06"]}
  end

  def comment_files_full
    full_timeline.merge({"2005" => ["12"], "2006" => all_months, "2007" => all_months})
  end

  def comment_files_test
    {
      "2006" => ["01", "02"]
    }
  end
  
  def comment_files_early_reddit
    {"2008" => ["04", "05", "06", "07", "08", "09", "10", "11", "12"], "2009" => ["01", "02", "03", "04", "05", "06"]}
  end
end