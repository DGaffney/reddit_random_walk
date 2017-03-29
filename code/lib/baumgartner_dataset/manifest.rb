module BaumgartnerManifest
  def submission_files_real
    {
      "2006" => "01".upto("12").to_a,
      "2007" => "01".upto("12").to_a,
      "2008" => "01".upto("12").to_a,
      "2009" => "01".upto("12").to_a,
      "2010" => "01".upto("12").to_a,
      "2011" => "01".upto("12").to_a,
      "2012" => "01".upto("12").to_a,
      "2013" => "01".upto("12").to_a,
      "2014" => "01".upto("12").to_a,
      "2015" => "01".upto("12").to_a,
      "2016" => "01".upto("02").to_a
    }
  end

  def submission_files_test
    {
      "2006" => "01".upto("10").to_a
    }
  end

  def comment_files
    {
      "2006" => "01".upto("12").to_a,
      "2007" => "01".upto("12").to_a,
      "2008" => "01".upto("12").to_a,
      "2009" => "01".upto("12").to_a,
      "2010" => "01".upto("12").to_a,
      "2011" => "01".upto("12").to_a,
      "2012" => "01".upto("12").to_a,
      "2013" => "01".upto("12").to_a,
      "2014" => "01".upto("12").to_a,
      "2015" => "01".upto("12").to_a,
      "2016" => "01".upto("02").to_a
    }
  end

  def comment_files_test
    {
      "2006" => "01".upto("10").to_a
    }
  end
end