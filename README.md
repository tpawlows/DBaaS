# DBaaS
DBaaS (PostgreSQL) that is run using Crunchy's Postgres Operator on top of k8s cluster set up using kOps on AWS.

## What is DBaaS?
The term “Database-as-a-Service” (DBaaS) refers to software that enables users to setup, operate and scale databases using a common set of abstractions (primitives), without having to either know nor care about the exact implementations of those abstractions for the specific database [[1]](https://www.stratoscale.com/blog/dbaas/what-is-database-as-a-service).

## What are key characteristics of a DBaaS?
- **Self-service**: DBaaS allows the provision of Databases effortlessly to Database consumers from various backgrounds and IT experience.
- **On-demand**: While generating overall IT savings, You pay for what you use.
- **Dynamic**: Based on the resources available, it delivers a flexible Database platform that tailors itself to the environment’s current needs.
- **Security** - A team of experts at your disposal, continuously monitoring your Databases.
- **Automation**: Automates Database administration and monitoring.
- **Leverage**: Leverages existing servers and storage[[2]](https://www.xenonstack.com/insights/what-is-database-as-a-service).

## What are the Common Features of DBaaS?
•	**Automation**. Database administration, access control, monitoring, and several other tasks are completely automated. The customers do not need to concern themselves with these tasks, since they are designed in a manner that the machine itself will automatically execute all tasks without any human intervention.
•	**Self-service capabilities**. Since the DBaaS software is fully automated, admin tasks can be automated as well. These tasks can be scheduled to support different database activities. DBaaS providers will support numerous automated tasks such as OS and kernel updates, back-up scheduling and restoration, software patching, and built-in replication among others.
•	**On-demand usage**. Users can opt for the DBaaS as per requirement, and it only takes a couple of minutes to set up. There are overall IT savings since the customer will only pay as per usage.
•	**Dynamic.** The DBaaS software is a flexible platform and will use the resources available as required. It will tailor itself to match the user’s environment needs.
•	**True high availability (HA) and resilience**. DBaaS systems need to show true HA so that the system is dependable enough to continuously work without any errors. For a DBaaS system, HA means that users can run several critical applications and workloads without having to worry about a database failing or becoming unavailable due to any failure [[7]](https://www.g2.com/categories/database-as-a-service-dbaas).

## Raison d'etre.
The reason for existence for this repository is to verify if it is possible to create a DBaaS of High Availability using Kubernetes Operator on top of a public cloud and then test if it maintains it's HA during typical Day-2 operations like: **scaling up/down/out/in, backup** and **version upgrade**). The work of this project focuses on building the whole solution (except creating GUI system to provision database and billing), which is:
- Choosing Cloud Service Provider: **AWS**
- Provisioning kuberentes in cloud **kOps** (kubernetes Operations)
	- More Cloud Agnostic approach
- Monitoring of an infrastructure: **Prometheus**
- Creaing dashboards with telemetry for efficient observability: **Grafana**
- Exposing web services available from a browser: **Ingress + NGINX Ingress Controller**
	- prometheus.k8s.retipuj.com
	- grafana.k8s.retipuj.com
	- pgadmin4.k8s.retipuj.com 
- Exposing database endpoint and operator using: **AWS LoadBalncers**
	- hippo.k8s.retipuj.com
	- pgo.k8s.retipuj.com
- Acess through DNS name with automatic updating DNS server: **external dns** 
- Automatic management of TLS/SSL certificates: **cert-manager**
- Choosing database type: **PostgreSQL**
- Deploying chosen kubernetes operator: **Crunchy Postgres Operator**[[6]](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- Creating LoadBalancer for Postgres Cluster: **pgpool-II**
- Creating Service discovery for telemetry: **annotations in kubernetes service objects**
- Generating load for testing: **pgbench**

The goal of this project is to answer the question, **wether kubernetes has matured enough, so it can be an environment where one can deploy production grade databases**. It will be done by evaluating created service in context of DBaaS key characteristics presented above and testing how the service behave (mainly in context of HA) during typical Day-2 Operations (while handling generated load) like:
- **Scaling out**
	- *Scaling out application means to add another instance of an application to the existing group*
- **Scaling in**
	- *Scaling in application means to remove one instance of an application from the existing group*
- **Scaling up**
	- *Scaling up application means to move application from a machine with lower compute resources to the one with more resources*
- **scaling down**
	- *Scaling down application means to move application from a machine with higher compute resources to the one with less resources*
- **Version Upgrade**
	- *Version upgrade means to replace container with postgres database from an older one to new one*
- **Backup**
	- *Backup is a copy of computer data taken and stored elsewhere so that it may be used to restore the original after a data loss event*

## Infrastructure
- Everything deployed on AWS
- Infrastructure should be similar to thos of production-grade 
- Kubernetes deployed using kOps
	- 2 master nodes
	- 2 worker nodes for non-database cluster objects
	- 2-3 worker nodes  (called hippo-nodes) for database cluster only
	- utilize t3.medium instances
- Cluster deployed in one Availablility Zone (eu-north-1a) in one Region (Stockholm)
- Cluster deployed in Private subnet
	- Access through NAT Gateway
- Exposed available through DNS names
- Encrypted traffic for web services and database cluster
- Automated:
	- TLS/SSL certification management
	- Service discovery for prometheus exporter
	- DNS server updates
- Used pod antiaffinity, node affinity and taints&tolerations, so database instances are deployed across dedicated nodes
- Database Cluster deployed using Operator, not Statefulset
 
## Exposed services
- https://prometheus.k8s.retipuj.com
	- Prometheus is an open-source systems monitoring and alerting toolkitPrometheus is a monitoring solution for recording and processing any purely numeric time-series. It gathers, organizes, and stores metrics along with unique identifiers and timestamps. Prometheus is open-source software that collects metrics from targets by "scraping" metrics HTTP endpoints [[3]](https://sensu.io/blog/introduction-to-prometheus-monitoring).
- https://grafana.k8s.retipuj.com
	- Grafana is a multi-platform open source analytics and interactive visualization web application. It provides charts, graphs, and alerts for the web when connected to supported data sources [[4]](https://en.wikipedia.org/wiki/Grafana).
- https://pgadmin4.k8s.retipuj.com
	- pgAdmin is the leading Open Source management tool for Postgres, the world's most advanced Open Source database. pgAdmin 4 is designed to meet the needs of both novice and experienced Postgres users alike, providing a powerful graphical interface that simplifies the creation, maintenance and use of database objects [[5]](https://www.pgadmin.org/docs/pgadmin4/development/index.html).
- hippo.k8s.retipuj.com
	- An endpoint to deployed Postgres Cluster. Cluster is called hippo.
- pgo.k8s.retipuj.com
	- An endpoint to deployed Crunchy Postgres Operator to manage deployed Postgres Cluster.

## References
1. https://www.stratoscale.com/blog/dbaas/what-is-database-as-a-service.
2. https://www.xenonstack.com/insights/what-is-database-as-a-service
3. https://sensu.io/blog/introduction-to-prometheus-monitoring
4. https://en.wikipedia.org/wiki/Grafana
5. https://www.pgadmin.org/docs/pgadmin4/development/index.html
6. https://access.crunchydata.com/documentation/postgres-operator/latest
7. https://www.g2.com/categories/database-as-a-service-dbaas
