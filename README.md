## Reddit's Random Walk
 
This is a replication repository that will eventually be a reference for a forthcoming paper exploring the degree to which the variance of cumulative posting behavior on Reddit can be estimated accurately by a simple random walk model. The draft paper along with code to replicate the results are located in the paper and code folders, respectively.

### Installation & Requirements

You need a few tools and a minimum system setup in order to analyze the dataset directly for replication purposes. In terms of installation, the machine you run this on assumes (though this may work on other setups) an Ubuntu 16.04 box, MongoDB 3.2.9, Redis 3.0.6, Ruby 2.3.0, and [jq](https://stedolan.github.io/jq/). Please ensure that you have these dependencies installed before attempting to generate any results.

### Running 

In order to replicate, you'll have to download 53GB of submissions, 200GB of comments, and around 1GB of missing data. For many people, this data may already be downloaded. If it is already downloaded locally, you will need to place all the raw files in exactly these positions in order for downstream analysis to work:
```
.
├── data
│   ├── all_active_reddit_days.txt
│   └── baumgartner
│       ├── comments
│       │   ├── RC_2005-12.bz2
│       │   ├── RC_2006-01.bz2
│       │   ├── RC_2006-02.bz2
│       │   ├── RC_2006-03.bz2
│       │   ├── RC_2006-04.bz2
                ..............
                ..............
                ..............
│       │   ├── RC_2015-08.bz2
│       │   ├── RC_2015-09.bz2
│       │   ├── RC_2015-10.bz2
│       │   ├── RC_2015-11.bz2
│       │   ├── RC_2015-12.bz2
│       │   ├── RC_2016-01.bz2
│       │   └── RC_2016-02.bz2
│       ├── missing_data
│       │   ├── missing_comments.json
│       │   └── missing_subreddits_0-10m.json
│       └── submissions
│           ├── RS_2006-01.bz2
│           ├── RS_2006-02.bz2
│           ├── RS_2006-03.bz2
│           ├── RS_2006-04.bz2
                ..............
                ..............
                ..............
│           ├── RS_2015-08.bz2
│           ├── RS_2015-09.bz2
│           ├── RS_2015-10.bz2
│           ├── RS_2015-11.bz2
│           ├── RS_2015-12.bz2
│           ├── RS_2016-01.bz2
└──         └── RS_2016-02.bz2
```

`missing_comments.json` and `missing_subreddits_0-10m.json` are available [here](http://www.devingaffney.com/files/missing_comments_and_early_missing_submissions.zip). If you do not yet have all this data already and in place for this project, then simply run `rake download` in the project's root directory in order to download all data.

Next, run `rake prepare` in order to extract, sort, and generate all transitions for all users for all of Reddit. At this point you'll be presented with a dialog that tells you to start a sidekiq instance - please do this by opening another terminal window in the same project directory as follows: `sidekiq -r ./environment.rb -c 10 -q daily_edges_redis`. This starts up workers that will concurrently work through a few tasks that ultimately creates a file, `data/baumgartner_concatenated/all_transitions.csv`, that has the following structure:

```
[source_subreddit],[target_subreddit],[transition_time],[screen_name],[interevent_time]
```

For all transits for all users, counting both comments as well as submissions. Additionally, it creates a file `data/baumgartner_user_counts_summarized.csv` that stores the total number of comments/submissions for all users on Reddit. At this point, you are now ready to start generating results. In this step, you're able to control the time resolution as well as the user activity percentile - the time window is controlled by the standard strftime format - "%Y" will generate year-over-year transitions, "%Y-%m" will generate month-over-month transitions, "%Y-%m-%d" will generate day-over-day transitions, "%Y-%W" will generate week-over-week transitions, and so forth. User activity percentile restricts the users who's transits will be included - a value of 0.0 means that All users will be used, while a value of 0.25 means only the top 75% of users measured by total number of comments/submissions will be used - 0.5 for top 50%, 0.75 for top 25%, and so forth. To run this, we simply use `rake full_live_run["[strftime_format]","[user_activity_percentile]"]`. After this, a new file will be present in the root directory, `error_diffs_[strftime_format]_[user_activity_percentile]_sequential.csv`, which contains the final output, and each row is of the following form:

`[subreddit],[total_number_of_comments_or_submissions],[total_number_of_time_slices_present],[average_error_per_timestep],[average_percent_of_activity_attributable_to_random_walk_assumption_per_timestep]`

The average error per timestep is the average percent difference between the percent of traffic source nodes sent to the target node an the percent we would assume under random walk conditions. The average percent attributable is this same figure but in terms absolute difference in terms of the number of discrete transitions for a time step.

To summarize, if we wanted to generate all transits for all users on Reddit given just this repository and no downloaded data, we would use the following chain of commands (assuming we want daily timesteps and all users):

* `sudo mongod` #start database
* `sudo redis-server` #start redis
* `rake download` #download dataset
* `rake prepare` #extract useful fields, generate transition data
* `sidekiq -r ./environment.rb -c 10 -q daily_edges_redis` #start workers
* `rake full_live_run["%Y-%m-%d","0.0"]` #generate results
