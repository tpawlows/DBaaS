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

## Raison d'etre.
The reason for existence for this repository is to verify if it is possible to create a DBaaS of High Availability using Kubernetes Operator on top of a public cloud and then test if it maintains it's HA during typical Day-2 operations like: **scaling up/down/out/in, backup** and **version upgrade**). The work of this project focuses on building the whole solution (except creating GUI system to provision database and billing), which is:
- Choosing Cloud Service Provider: **AWS**
- Provisioning kuberentes in cloud **kOps** (kubernetes Operations)
	- More Cloud Agnostic approach
- Monitoring of an infrastructure: **Prometheus**
- Creaing dashboards with telemetry for efficient observability **Grafana**
- Exposing web services available from a browser **Ingress + NGINX Ingress Controller**
	- prometheus.k8s.retipuj.com
	- grafana.k8s.retipuj.com
	- pgadmin4.k8s.retipuj.com 
- Exposing database endpoint and operator using **AWS LoadBalncers**
	- hippo.k8s.retipuj.com
	- pgo.k8s.retipuj.com
- Acess through DNS name with automatic updating DNS server **external dns** 
- Automatic management of TLS/SSL certificates **cert-manager**
- Choosing database type **PostgreSQL**
- Deploying chosen kubernetes operator **Crunchy Postgres Operator**[[6]](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- Creating LoadBalancer for Postgres Cluster **pgpool-II**
- service discovery for telemetry **annotations in kubernetes service objects**

The goal of this project is to answer the question, **wether kubernetes has matured enough, so it can be an environment where one can deploy production grade databases**. It will be done by evaluating created service in context of DBaaS key characteristics presented above and testing how the service behave (mainly in context of HA) during typical Day-2 Operations like:
- scaling out
- scaling in
- scaling up
- scaling down
- version upgrad
- backup

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
