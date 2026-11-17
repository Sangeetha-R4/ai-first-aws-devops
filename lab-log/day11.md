# Day 11 — CP Domain 3: Compute, Storage, Databases (part 1 of 2)

**Date:** 2026-11-16 (session 1 of the 37-session plan)
**Goal:** First half of CP Domain 3 — the service catalogue.
**Exam weight:** Domain 3 = **34%** (the biggest domain)

---

## Segment 1 — Compute

### The catalogue

| Service | What it is | Choose when |
|---|---|---|
| **EC2** | virtual servers | need OS control |
| **Lambda** | serverless functions | event-driven, spiky, <15 min |
| **ECS** | container orchestration (AWS-native) | want simple container running |
| **EKS** | managed Kubernetes | need the K8s ecosystem |
| **Fargate** | serverless containers (ECS **or** EKS) | no servers to manage |
| **Elastic Beanstalk** | PaaS — upload code, it provisions | simplest path, least control |
| **Batch** | managed batch compute | large-scale job processing |
| **Lightsail** | fixed-price simple VPS | small projects, predictable bill |

### EC2 instance families

```
m5.large
│ │  └── size: nano … large, xlarge, 2xlarge
│ └──── generation
└────── family letter
```

| Family | Optimised for | Use case |
|---|---|---|
| **T** | burstable | web servers, dev, low baseline |
| **M** | **general purpose** | most workloads — the default |
| **C** | **compute** | batch, encoding, high-perf web |
| **R** | **memory** | databases, caching, in-memory analytics |
| **I / D** | storage (IOPS / dense) | NoSQL, data warehouses |
| **G / P** | GPU | ML training, rendering |
| **X / z** | extreme memory | SAP HANA, huge in-memory DB |

### Burstable — the T-family trap

T instances run at a **baseline CPU percentage** and earn **credits** when idle, spending them when busy.

**If credits are exhausted, the instance is throttled to baseline.** That is why T is wrong for sustained load.

```
t3.medium baseline = 20% of 2 vCPU
Sustained DB load  = 60% CPU
→ credits exhaust in ~30 min → throttled to 20% → queries queue → outage
```

**I got the reason wrong in the checkpoint** — said "tiny memory". **Memory depends on size** (`t3.large` = 8 GB). The real reason is **CPU credit exhaustion under sustained load**. Databases need **M or R** families.

### Lambda constraints

| Limit | Value |
|---|---|
| **Max execution time** | **15 minutes** |
| Memory | 128 MB – 10 GB |
| Deployment package | 50 MB zipped / 250 MB unzipped |
| Billing | per request + per **GB-second** |

**Exam trigger:** *"task takes 20+ minutes"* → **not Lambda.** Use ECS, Batch, or Step Functions.

**Lambda's real strength:** scales to zero — pay nothing when idle.

### ECS vs EKS vs Fargate — the false choice

```
ECS  ─ orchestration engine (AWS-native, simpler)
EKS  ─ orchestration engine (Kubernetes, standard, complex)
   ↓ either runs on:
EC2 launch type      → you manage the servers
FARGATE launch type  → AWS manages the servers
```

| | **ECS** | **EKS** |
|---|---|---|
| Complexity | lower | higher |
| Ecosystem | AWS-specific | huge (Helm, ArgoCD, operators) |
| Portability | AWS-locked | portable |
| Choose when | AWS-only, want simple | multi-cloud, existing K8s skills |

**Fargate is a launch type, not an alternative to ECS/EKS.** "Fargate or ECS?" is a false choice — Fargate is *how* you run ECS.

### Beanstalk vs CloudFormation

| | **Elastic Beanstalk** | **CloudFormation** |
|---|---|---|
| What | **PaaS** — upload code, it provisions | **IaC** — you declare the resources |
| Control | low | high |
| User | developers | engineers |
| Analogy | "here's my app, run it" | "here's exactly what to build" |

### Batch vs Lambda

| | **Batch** | **Lambda** |
|---|---|---|
| Duration | any | 15 min max |
| Use | ETL, rendering, scientific | events, APIs, glue |

**"Process 10,000 videos overnight" → Batch. "Resize this image on upload" → Lambda.**

**Checkpoint score: 6/7** (the T-family reasoning).

---

## Segment 2 — Storage

### S3 fundamentals

| Property | Value |
|---|---|
| **Durability** | **11 nines** (99.999999999%) |
| **Availability** | 99.99% Standard |
| Namespace | **global** — bucket names unique across all AWS |
| Object size | up to **5 TB** (5 GB per PUT, multipart above 100 MB) |
| Structure | **flat** — "folders" are key prefixes |
| Consistency | **strong read-after-write** since 2020 |

### Durability vs availability — the classic distinction

| | Durability | Availability |
|---|---|---|
| Means | **won't lose** the data | **can I reach it now** |
| S3 Standard | 11 nines (≈0.000000001%/yr loss) | 99.99% (≈52 min downtime/yr) |

**My answer was incomplete** — said only "data is never lost". The distinction is the exam point.

### S3 storage classes

| Class | Retrieval | Min duration | Use when |
|---|---|---|---|
| **Standard** | instant | none | frequently accessed |
| **Intelligent-Tiering** | instant | none (small fee) | **unknown/changing access** ← safest default |
| **Standard-IA** | instant | 30 days | infrequent, instant access needed |
| **One Zone-IA** | instant | 30 days | **reproducible** data only (single AZ) |
| **Glacier Instant Retrieval** | ms | 90 days | archive, instant access |
| **Glacier Flexible Retrieval** | min–hours | 90 days | archive, delay tolerable |
| **Glacier Deep Archive** | **12 hours** | 180 days | **cheapest** — compliance archive |

**Trigger phrases:**

| Question says | Answer |
|---|---|
| "accessed once or twice a year, cheapest" | **Glacier Deep Archive** |
| "unpredictable access" | **Intelligent-Tiering** |
| "can be regenerated if lost" | **One Zone-IA** |
| "archive but retrievable instantly" | **Glacier Instant Retrieval** |

**One Zone-IA trap:** single AZ — lose the AZ, lose the data. Only for reproducible data.

**Minimum-duration caveat:** delete before the class minimum (30/90/180 days) and **you're billed for the full minimum anyway.**

### Lifecycle policies

```
Day 0    → Standard
Day 30   → Standard-IA
Day 90   → Glacier Flexible Retrieval
Day 365  → delete
```

**The biggest S3 cost lever.** Forgotten objects in Standard cost 5–20× their Glacier equivalent.

### Other S3 features

Versioning · MFA delete · **Object Lock (WORM)** · Cross-region replication · Same-region replication · **Transfer Acceleration** · **presigned URLs** (time-limited access to private objects) · static website hosting · event notifications → Lambda/SQS/SNS · Access Points.

### EBS volume types

| Type | Use | Notes |
|---|---|---|
| **gp3** | **general purpose — the default** | 3,000 IOPS / 125 MB/s baseline |
| gp2 | older general purpose | **IOPS tied to volume size** (3 IOPS/GB) |
| **io2 Block Express** | highest performance | up to 256,000 IOPS |
| io1 | high performance | superseded by io2 |
| **st1** | throughput-optimised HDD | sequential, big data, logs |
| **sc1** | cold HDD | lowest cost, infrequent |
| **Instance store** | physically attached NVMe | **ephemeral — lost on stop/terminate** |

**Why gp3 replaced gp2:** gp2 **coupled IOPS to volume size**, so you over-provisioned storage just to get performance. **gp3 decouples IOPS and throughput from size**, with a cheaper baseline.

### EBS vs instance store

| | **EBS** | **Instance store** |
|---|---|---|
| Persistence | survives stop/start | **lost on stop or terminate** |
| Attachment | network | **physically attached** |
| Latency | network | **lowest** |
| Cost | extra | **included in instance price** |
| Use | anything to keep | cache, scratch, temp |

**"Data must survive restart" → EBS, never instance store.**
**"Temp files, safe to lose" → instance store** — faster and already paid for.

**EBS is AZ-scoped:** a volume attaches only to instances in the **same AZ**. To move: snapshot → create in the target AZ.

### EBS vs EFS vs FSx

| | **EBS** | **EFS** | **FSx** |
|---|---|---|---|
| Type | block | **file (NFS)** | file (SMB / Lustre) |
| Attached to | one instance | **many instances** | many |
| AZ scope | **single AZ** | **multi-AZ** | depends |
| OS | any | **Linux only** | Windows / Linux HPC |
| Use | boot volumes, databases | shared content | Windows shares, HPC |

**"Multiple Linux instances across AZs need shared storage" → EFS.** EBS cannot (single AZ, single instance).

### Migration & hybrid

| Service | Use |
|---|---|
| **Storage Gateway** | on-prem apps use cloud storage via NFS/SMB/iSCSI |
| **Snowball Edge** | physical device — TB to PB offline transfer |
| **Snowmobile** | container — up to 100 PB |
| **DataSync** | automated network transfer |
| **Transfer Family** | SFTP/FTPS into S3 |

**Snowball trigger:** *"300 TB, link would take 8 months"* → ship a device.

**Checkpoint score: 6/8** (missed the durability-vs-availability contrast, and the gp2/gp3 "why").

---

## Segment 3 — Databases

### The decision tree

```
Relational + managed           → RDS
Relational + high performance  → Aurora
Massive scale, key-value       → DynamoDB
Analytics over TB/PB           → Redshift
Cache in front of a database   → ElastiCache
MongoDB-compatible             → DocumentDB
Relationship-heavy queries     → Neptune
Immutable audit ledger         → QLDB
Time-series                    → Timestream
```

### RDS — managed relational

Engines: MySQL · PostgreSQL · MariaDB · **Oracle** · **SQL Server**

**Managed removes:** OS patching, engine patching, backups, failover, monitoring.

### Multi-AZ vs Read Replica — tested every single time

| | **Multi-AZ** | **Read Replica** |
|---|---|---|
| Purpose | **availability / DR** | **read scalability** |
| Replication | **synchronous** | **asynchronous** |
| Failover | **automatic** | manual promotion |
| Standby readable? | ❌ **no** | ✅ yes |
| Cost | 2× (you pay for standby) | per replica |

**Triggers:**
- *"survive an AZ failure without manual intervention"* → **Multi-AZ**
- *"reporting queries slowing the app"* → **Read Replica**

**Both can be used together.** Multi-AZ for HA + replicas for reads.

### Aurora

| Property | Detail |
|---|---|
| Compatibility | **MySQL and PostgreSQL only** |
| Performance | ~**5× MySQL**, ~3× PostgreSQL |
| Storage | **auto-scales** in 10 GB steps to 128 TB |
| Replication | **6 copies across 3 AZs** |
| Failover | typically **< 30 seconds** |
| Replicas | up to **15** |
| Extras | **Serverless v2** (auto capacity), **Global Database** (cross-region, <1s lag) |

**When Aurora:** high performance, unpredictable storage growth, faster failover, MySQL/PG acceptable.
**When plain RDS:** need **Oracle or SQL Server** (Aurora doesn't support them), or cost matters more.

**I inverted this in the checkpoint** — listed Aurora's *limitations* instead of its advantages.

### DynamoDB

| Property | Detail |
|---|---|
| Model | **key-value / document** |
| Performance | **single-digit ms at any scale** |
| Scaling | automatic, **serverless** |
| Capacity | **On-Demand** or **Provisioned** (RCU/WCU) |
| Extras | **Global Tables** (multi-region active-active), **Streams** → Lambda, **DAX** cache, **TTL** |

**When DynamoDB:** massive scale, predictable key access, zero server management, mobile/IoT/sessions/leaderboards.

**When NOT:** complex joins, ad-hoc queries, reporting. **No SQL, no joins.**

**Exam trap:** *"complex queries with joins"* → **NOT DynamoDB.**

### Redshift — OLAP

Columnar, massively parallel. SQL, optimised for aggregation over TB–PB. **Spectrum** queries S3 directly without loading.

### OLTP vs OLAP — the distinction

| | **OLTP** (RDS, Aurora, DynamoDB) | **OLAP** (Redshift) |
|---|---|---|
| Workload | many small transactions | few large analytical queries |
| Optimised | writes, point lookups | scans + aggregation |
| Example | "get order 12345" | "revenue by region per month" |

**"Analyse 5 years of sales data" → Redshift, not RDS.**

### ElastiCache

| Engine | Use |
|---|---|
| **Redis** | **persistence**, pub/sub, sorted sets, replication — richer |
| **Memcached** | simple, multi-threaded, no persistence |

**Use for:** session stores, query caching, leaderboards, rate limiting.

**Why Redis for sessions:** it **persists to disk**, so a cache restart doesn't log every user out or empty their cart. **Memcached loses everything on restart** — fine for pure object caching, wrong for sessions.

### Specialist databases — awareness only

| Service | Type | Use |
|---|---|---|
| **DocumentDB** | MongoDB-compatible | existing Mongo workloads |
| **Neptune** | graph | social, fraud detection, recommendations |
| **QLDB** | ledger, immutable | audit trails, financial records |
| **Timestream** | time-series | IoT metrics, telemetry |
| **Keyspaces** | Cassandra-compatible | wide-column |

### Durability by service

| Service | Durability |
|---|---|
| S3 | 11 nines |
| **Aurora** | 6 copies across 3 AZs |
| **DynamoDB** | replicated across 3 AZs |
| RDS | Multi-AZ synchronous standby |

**Checkpoint score: 6/8** (inverted Aurora advantages; missed the Redis persistence reason).

---

## Scorecard — session 1

| Segment | Score |
|---|---|
| 1. Compute | **6/7** |
| 2. Storage | **6/8** |
| 3. Databases | **6/8** |
| **Total** | **18/23** |

## Five things to drill before practice exam #1

1. **T-family = burstable, CPU credits → throttled.** Not a memory issue.
2. **Durability ≠ availability.** 11 nines = won't lose; 99.99% = can reach.
3. **gp3 decoupled IOPS from size** — that's what killed gp2.
4. **Aurora's advantages** — 5× perf, auto-scaling storage to 128 TB, 6 copies/3 AZs, <30s failover, 15 replicas. (Its *limits*: no Oracle/SQL Server, higher cost.)
5. **Redis persists; Memcached doesn't** — that's why Redis for sessions.

---

## What I learned (in my own words)

*(fill in — 3-5 sentences: how would you choose between RDS, Aurora and DynamoDB for a new service? why does Multi-AZ cost twice as much as a single instance? what's the difference between durability and availability in your own words?)*
