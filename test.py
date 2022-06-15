tags=["2.9.5.1.4_props",'3.0.0.0.1.1.a','3.0.0.0.1.2.a']

cluster="a"
current_cluster_tags = []
for tag in tags:
    if cluster in tag:
        current_cluster_tags.append(tag.replace(".","").rstrip(cluster))


ver = max(current_cluster_tags)

print(ver)
latest_version = int(ver) + 1

print(latest_version)

L_Version = '.'.join(str(latest_version)[i:i + 1] for i in range(0, len(str(latest_version)), 1))














