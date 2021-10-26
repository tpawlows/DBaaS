
# Experiments
This section describes a set of tests that will be conducted on a DBaaS created in this repository. Experiments will be made of a 2 benchmark instances that will be launch on a local machine (Linux) and they will be sending READ/WRITE queries to the Postgres Cluster called **hippo**. Benchmarks will be run continuously time and their purpose is to generate a load on a Postgres Cluster. Then during benchmark run, a specific action will be placed (scaling,backup, version upgrade). After  few minutes (2-3) benchmark instances will be restarted to reconnect to hippo. Server side metrics from a postgres cluster will be collected using promethus and will be availabe fro viewing on grafana.

## Benchmark
For generating load, I will use **pgbench**, which very simple but useful tool for benchmarking postgres.
Database will be initialized with data scaling factor will be set to 100 (10,000,000 rows).
```bash
pgbench -i -s 100 hippo 
```
- There will be 2 instances of pgbench, one for READ-ONLY and second for READ-WRITE queries. 
- After operations, like scaling and version upgrade, pgbench benchmark instances will be restarted, because **pgbench doesn't have the logic to retry queries if they fail.** 
- If a Database Admin spawns another instance, then **no one from the clients, that already has established session with a database will be able to use new instance.**
- If cluster is scaled down or up or upgraded to a new version (which results in deleteing all instances and spawning new), benchmark will loose connection for all of it's clients.
- To reconnect to a cluster we will restart benchmark instances after operation and see the throughput

### Read only instance run command
```bash
pgbench -c 125 -j 8 -T 120 -S --no-vacuum hippo
```
### Read-Write instance run command
```bash
pgbench -c 25 -j 8 -T 120 --no-vacuum hippo
```

## Execution
- Each instance will be spawned on a seperate node (pod anti-affinity) dedicated only for postgres cluster instances (taints&tolerations + node affinity)
- most of benchmarks will be made for postgres cluster spawned on t3.medium instance (exception: scale down)
- At the beginning two instances of pgbench are created to generate load
  - READ-ONLY instance
  - READ-WRITE instance
- there are more read only queries because **only read queries will be load balanced**
- benchmark instances will run during operations
  - after operations, that requires scaling or restarting cluster instance, benchmark instances will be restarted to reconnecto to the cluster
- Experiment will last for 15 minutes
- 5 minutes after start, an operation will take place (scaling, upgrade or backup)
- after that for scaling and version update, benchmark restart will happen, when new state of the cluster will be met to reconnect all clients
- Experiment will follow for another 10 minutes to gather metrics necessary to evaluate database cluster behavior.

## Execution Schema
1. Spawn database cluster.
2. Generate load using pgbench.
3. Wait 5 minutes.
4. Run desired operation.
  - restart benchmark instances after few minutes to refresh connections
5. Wait another 10 minutes.
6. Gather results.

## Metrics collected
All metrics are exported using prometheus exporters (postgres exporter and cAdvisor)
- Currently connected clients
- Throughput per whole database cluster
- Latency per whole database cluster
- CPU Utilization per DB instance
- Memory Usage per DB instance
- Disk Reads per DB instance
- Disk Writes per DB instance
- Network Receive Rate per DB instance
- Network Transmit Rate per DB instance


## List of experiments
Refer to **operations/README.md**
- Scaling out
  - (1 primary, 1 replica) -> (1 primary, 2 replica)
- Scaling in
	- (1 primary, 2 replica) -> (1 primary, 1 replica)
- Scaling up 
  - (3 instances spawned on t3.medium) -> (3 instances spawned on t3.large)
- Scaling down
  - (3 instances spawned on t3.large) -> (3 instances spawned on t3.medium)
- Version upgrade
  - (3 instances of postgres version 13.3) -> (3 instances of postgres version 13.4)
- Backup
  - perform a backup during benchmark execution
