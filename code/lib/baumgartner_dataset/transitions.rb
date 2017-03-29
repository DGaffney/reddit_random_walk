module BaumgartnerTransitions
  def all_transitions
    "#{ENV["PWD"]}/data/baumgartner_concatenated/all_transitions.csv"
  end

  def generate_daily_edges
    all_activities_file_author_time_sorted
    ij = 0
    csv = CSV.open(all_transitions, "w")
    cur_user = []
    cur_count = 0
    CSV.foreach(all_activities_file_author_time_sorted) do |row|
      next if row.empty? || row[2] == "[deleted]" || row[2].nil?
      ij += 1
      cur_count += 1
      if !cur_user.empty? && cur_user.first[2] != row[2]
        sorted_interactions = cur_user.sort_by{|r| r.first.to_i}
        if sorted_interactions.count > 1
          sorted_interactions[0..-2].each_with_index do |post, i|
            csv << [post[1], sorted_interactions[i+1][1], sorted_interactions[i+1][0], cur_user.first[2]]
          end
        end
        cur_user = [row]
      end
      cur_user << row
      puts cur_count if cur_count % 10000 == 0
    end;false
    csv.close
  end
  #this is difficult since we have to account for user activity as well as time resolution. this is where the meat of the code is.
  def generate_daily_edges
    current_count = 0
    cur_dataset = {}
    csv = CSV.foreach(all_transitions) do |row|
      cur_dataset[Time.parse(row.first.to_i).strftime(strftime_setting)]
      "#{ENV["PWD"]}/data/baumgartner_daily"
    end
  end
end