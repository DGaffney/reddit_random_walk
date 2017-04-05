module BaumgartnerTransitions
  def all_transitions
    "#{project_folder}/data/baumgartner_concatenated/all_transitions.csv"
  end

  def transition_slice_manifest_file(strftime_str)
    "#{project_folder}/data/baumgartner_concatenated/transitions_#{strftime_str}.csv"
  end


  def user_count_file
    "#{project_folder}/data/baumgartner_user_counts.csv"
  end

  def user_count_file_summarized
    "#{project_folder}/data/baumgartner_user_counts_summarized.csv"
  end

  def time_transitions_summarized
    "#{project_folder}/data/baumgartner_time_transitions_summarized"
  end

  def mkdir_time_transitions_summarized
    `mkdir #{time_transitions_summarized}`
  end

  def time_transitions
    "#{project_folder}/data/baumgartner_time_transitions"
  end

  def mkdir_time_transitions
    `rm -r #{time_transitions}`
    `mkdir #{time_transitions}`
  end

  def generate_transitions
    ij = 0
    csv = CSV.open(all_transitions, "w")
    user_csv = CSV.open(user_count_file, "w")
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
            csv << [post[1], sorted_interactions[i+1][1], sorted_interactions[i+1][0], cur_user.first[2], sorted_interactions[i+1][0].to_i-post[0].to_i]
            user_csv << [cur_user.first[2]]
          end
        end
        cur_user = [row]
      end
      cur_user << row
      puts cur_count if cur_count % 10000 == 0
    end;false
    csv.close
    user_csv.close
    `LC_ALL=C sort #{user_count_file} | uniq -c > #{user_count_file_summarized}`
  end
  
  def generate_edge_transitions_by_timeframe(strftime_str)
    RedisStorer.set_json("global_user_counts#{@method_suffix}", Hash[CSV.read(user_count_file_summarized, col_sep: " ").collect{|x| x = x.reverse; [x[0], x[1].to_i]}])
    `rm -r #{time_transitions_summarized}`
    ii = 0
    buffer = {}
    buffer_count = 0
    mkdir_time_transitions
    time_slices = {}
    CSV.foreach(all_transitions, "r") do |row|
      day = Time.at(row[2].to_i).strftime(strftime_str)
      time_slices[day]||=nil
      buffer[day] ||= []
      buffer[day] << row
      buffer_count += 1
      if buffer_count == 1000
        buffer.each do |buffer_day, rows|
          `echo '#{rows.collect{|r| [r[0], r[1], r[3]].join(",")}.join("\n")}' >> #{time_transitions}/#{buffer_day}`
        end
        buffer = {}
        buffer_count = 0
      end
      ii += 1
      puts ii if ii % 10000 == 0
    end;false
    buffer.each do |buffer_day, rows|
      `echo '#{rows.collect{|r| [r[0], r[1], r[3]].join(",")}.join("\n")}' >> #{time_transitions}/#{buffer_day}`
    end
    time_slice_key = CSV.open(transition_slice_manifest_file(strftime_str), "w")
    time_slices.keys.sort.collect{|ts| time_slice_key << [ts]}
    time_slice_key.close
    `mkdir #{time_transitions_summarized}`
    time_slices.keys.each do |time_slice|
      `LC_ALL=C sort #{time_transitions}/#{time_slice} | uniq -c >> #{time_transitions_summarized}/#{time_slice}`
    end
  end

  def summarize_transitions(strftime_str, percentile, only_higher=false)
    mkdir_time_transitions_summarized
    cumulative_post_cutoff = RedisStorer.get_json("global_user_counts#{@method_suffix}").values.sort.percentile(percentile)
    CSV.read(transition_slice_manifest_file(strftime_str)).flatten.each do |file|
      StoreDailyTrafficToRedis.perform_async(@method_suffix, file, strftime_str, cumulative_post_cutoff, percentile, only_higher)
    end
    puts "
    ==============================================YO BIRD UP!================================================
    Jobs queued for strftime of #{strftime_str} and user activity percentile of #{percentile}. 
    Please start a sidekiq instance to start storing all edges into memory (Note: on a full dataset 
    please ensure at least 10GB of completely free RAM). Once complete, the data will be stored into whatever
    Redis Database file you are currently using (#{RedisStorer.get_current_db_location} currently). 
    Since the Reddit dataset is very large, you should limit each .rdb file to just a single snapshot of data
    (e.g. a time resolution of daily (%Y-%m-%d for example) and activity percentile (0.25 for example)). After 
    you've generated the data and collected the final random walk assumption vs observed data and it's stored
    to disk, you should stop running this software, move the .rdb file elsewhere, give it a name that reflects 
    the options you specified, and restart anew for some new slice of time. Failure to follow these 
    instructions will result in a major headache you don't want to deal with and you should follow this info.
    This task will continue running until all storage jobs have completed, and when all transitions are 
    stored to memory, it will continue processing the data and converting the transitions with the given time
    resolution and activity percentile until flat files have been generated. It will then let you know where
    the output is located, and then quit. Start up the sidekiq instance now by opening another window in 
    this directory, and running `sidekiq -r ./environment.rb -c 10 -q daily_edges_redis` - `-c` parameter
    controls concurrency - make it higher for faster processing for the sake of higher RAM and CPU usage, 
    and lower for the opposite objective.
    ======================================CATCH YOU IN THE QUAD HOLMES======================================"
    while Sidekiq::Queue.new("daily_edges_redis").size+Sidekiq::RetrySet.new.size > 0
      sleep(1)
    end
  end
end

