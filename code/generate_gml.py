import sys
import os
import math
import csv
import igraph
time_resolution = sys.argv[1]
dataset_tag = sys.argv[2]
files = [f for f in os.listdir("tergm_analysis") if time_resolution in f and dataset_tag in f]
def read_csv(filename):
  dataset = []
  i = 0
  with open(filename, 'rb') as f:
      reader = csv.reader(f)
      for row in reader:
        if i != 0: 
          dataset.append([row[0], row[1], int(row[2]), int(row[3]), int(row[4])])
        i += 1
  return dataset

def read_node_datasheet(filename):
  dataset = []
  i = 0
  with open(filename, 'rb') as f:
      reader = csv.reader(f)
      for row in reader:
        if i != 0:  
          dataset.append([row[0], int(row[1]), float(row[2]), float(row[3]), int(row[4]), int(row[5]), int(row[6]), int(row[7])])
        i += 1
  return dataset

subreddits = ["guns", "reddit.com", "politics", "programming", "pics", "AskReddit", "worldnews", "WTF", "science", "funny", "technology", "atheism", "entertainment", "business", "gaming", "offbeat", "Economics", "videos", "nsfw", "comics", "environment", "Music", "linux", "Marijuana", "geek", "gossip", "sports", "gadgets", "news", "obama", "canada", "Libertarian", "scifi", "philosophy", "Health", "bestof", "self", "movies", "web_design", "humor", "sex", "apple", "worldpolitics", "wikipedia", "math", "food", "conspiracy", "energy", "economy", "it", "MensRights"]

for file in files:
  raw_data = read_csv("tergm_analysis/"+file)
  node_data = read_node_datasheet("tergm_analysis_node_data/"+file)
  graph = igraph.Graph(directed=True)
  graph.add_vertices(subreddits)
  graph.add_edges([(el[0], el[1]) for el in raw_data])
  graph.es()['observed'] = [int(el[2]) for el in raw_data]
  graph.es()['previous'] = [int(el[3]) for el in raw_data]
  graph.es()['estimated'] = [int(el[4]) for el in raw_data]
  graph.vs()["default_status"] = 0
  graph.vs()["category"] = 0
  graph.vs()["political"] = 0
  graph.vs()["general"] = 0
  graph.vs()["technology"] = 0
  graph.vs()["traffic_count"] = 0
  graph.vs()["log_traffic_count"] = 0
  for node in node_data:
    graph_node = [n for n in graph.vs() if n['name'] == node[0]][0]
    graph_node["default_status"] = node[1]
    graph_node["traffic_count"] = node[2]
    graph_node["log_traffic_count"] = node[3]
    graph_node["category"] = node[4]
    graph_node["political"] = node[5]
    graph_node["general"] = node[6]
    graph_node["technology"] = node[7]
  graph.write_gml("tergm_analysis_gml/"+file)
