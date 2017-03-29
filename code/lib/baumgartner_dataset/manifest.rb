module BaumgartnerManifest
  def all_months
    "01".upto("12").to_a
  end

  def full_timeline
    res = {"2016" => ["01", "02"]}
    "2006".upto("2015").collect{|y| res[y] = all_months}
    res
  end

  def submission_files_real
    full_timeline
  end

  def submission_files_test
    {
      "2006" => "01".upto("10").to_a
    }
  end

  def comment_files
    full_timeline
  end

  def comment_files_test
    {
      "2006" => "01".upto("10").to_a
    }
  end
end