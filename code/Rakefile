load 'environment.rb'
require 'rake'
task :download_test do
  BaumgartnerDataset.new("test").download
end

task :prepare_test do
  BaumgartnerDataset.new("test").prepare
end

task :download do
  BaumgartnerDataset.new("full").download
end

task :prepare do
  BaumgartnerDataset.new("full").prepare
end

task :full_test_run, [:strftime, :percentile] do |t, args|
  args[:percentile] = args[:percentile]
  BaumgartnerDataset.new("test").store_sliced_transitions(args[:strftime], args[:percentile].to_f)
  BaumgartnerDataset.new("test").analyze_sliced_transitions(args[:strftime], args[:percentile].to_f)
end

task :full_live_run, [:strftime, :percentile] do |t, args|
  args[:percentile] = args[:percentile].to_f
  BaumgartnerDataset.new("full").store_sliced_transitions(args[:strftime], args[:percentile].to_f)
  BaumgartnerDataset.new("full").analyze_sliced_transitions(args[:strftime], args[:percentile].to_f)
end
#BaumgartnerDataset.new(true).analyze_sliced_transitions("%Y-%m-%d", 0.0)
