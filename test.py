import os
tags=["2.9.5.1.4_props",'3.0.0.0.1.1.a','3.0.0.0.1.2.a']

cluster=os.environ.get("cluster")
current_cluster_tags = []
for tag in tags:
    if cluster in tag:
        current_cluster_tags.append(tag.replace(".","").rstrip(cluster))
ver = max(current_cluster_tags)
os.environ['NAME'] = os.environ['NAME']+"test"
latest_version = int(ver) + 1
L_Version = '.'.join(str(latest_version)[i:i + 1] for i in range(0, len(str(latest_version)), 1))
NEW_VERSION = f'{L_Version}.{cluster}'
print(NEW_VERSION)
os.environ['NEW_VERSION'] = NEW_VERSION
