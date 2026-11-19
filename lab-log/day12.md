# Day 12 — CP Domain 3: Networking, Integration, Management (part 2 of 2)

**Date:** 2026-11-17 (plan session 2)
**Goal:** Second half of CP Domain 3 — networking, integration, management, AI/ML awareness.
**Exam weight:** Domain 3 total = 34% (part 1 covered compute/storage/databases)

**Note on coverage:** Segment 4 (networking) was taught interactively with a checkpoint. Segments 5–7 were covered in `docs/cp-domain3-reference.md` rather than checkpointed individually — the practice exam will test them.

---

## Segment 4 — Networking

### VPC shape

```
VPC 10.0.0.0/16
 ├── public subnet   → route to Internet Gateway
 ├── private subnet  → route to NAT Gateway (out only)
 └── isolated subnet → no internet route
```

| Component | Purpose |
|---|---|
| **Subnet** | slice of the VPC CIDR, **bound to one AZ** |
| **Route table** | no route = no connectivity |
| **Internet Gateway** | VPC ↔ internet, one per VPC |
| **NAT Gateway** | private → out only, **never free** |
| **Security group** | instance-level, stateful, allow-only |
| **NACL** | subnet-level, stateless, allow + deny |
| **VPC Endpoint** | reach AWS services without the internet |
| **Peering** | VPC ↔ VPC, **not transitive** |
| **Transit Gateway** | hub connecting many VPCs and on-prem |

**Subnets are AZ-bound** — a multi-AZ design needs one subnet per AZ. My account has three: `172.31.0.0/20`, `172.31.16.0/20`, `172.31.32.0/20` across `ap-south-1a/b/c`.

### Route 53 record types

| Type | Use | Note |
|---|---|---|
| **A** | name → IPv4 | |
| **AAAA** | name → IPv6 | |
| **CNAME** | name → another name | ❌ **cannot be used at zone apex** |
| **Alias** | name → **AWS resource** | ✅ works at apex, **free queries** |
| MX | mail | |
| TXT | verification, SPF | |

### The seven routing policies

| Policy | Basis | Trigger phrase |
|---|---|---|
| **Simple** | one record | basic setup |
| **Weighted** | percentage split | "send 10% to the new version" |
| **Latency** | lowest **measured network latency** | "fastest for global users" |
| **Failover** | health-check driven | "automatic failover to backup region" |
| **Geolocation** | user's **country / continent** | "EU users must hit EU servers" |
| **Geoproximity** | **physical distance** + adjustable bias | "gradually shift traffic between regions" |
| **Multivalue** | several healthy records | "simple load balancing across healthy endpoints" |

**The trap — latency vs geolocation vs geoproximity:**

| | Decided by |
|---|---|
| **Latency** | measured network speed — fastest wins |
| **Geolocation** | the user's **country**, regardless of speed |
| **Geoproximity** | **distance** from a resource, with a bias dial |

**"Data must stay in the EU for legal reasons" → geolocation.** Latency could legitimately route an EU user to a faster US region — which would break the regulation. That's the distinction the exam tests.

### CloudFront

| Property | Detail |
|---|---|
| Locations | **400+ edge locations** |
| Origin | S3, ALB, EC2, any HTTP endpoint |
| TTL + invalidation | cache lifetime; invalidation charged after 1,000/month |
| **Origin Access Control (OAC)** | S3 reachable **only** through CloudFront |
| Signed URLs / cookies | time-limited private content |
| Lambda@Edge / CloudFront Functions | code at the edge |

**"Users worldwide need fast static image delivery" → CloudFront**, not multiple regions. Regions duplicate the whole stack; edge locations just cache.

**Why OAC matters:** keep the bucket private, deny direct S3 access. Otherwise a user can bypass the CDN — and therefore bypass your WAF.

### API Gateway

| Type | Use |
|---|---|
| **REST** | full-featured — auth, caching, usage plans |
| **HTTP** | cheaper and simpler — the low-cost option |
| **WebSocket** | bidirectional, persistent connection |

**Serverless API stack = API Gateway + Lambda + DynamoDB.**

### Connectivity

| | **Site-to-Site VPN** | **Direct Connect** |
|---|---|---|
| Path | **public internet** (encrypted tunnel) | **dedicated private line** |
| Setup time | minutes | weeks to months |
| Bandwidth | variable | consistent, high |
| Latency | variable | **predictable** |
| Cost | low | high |

**"Consistent latency and traffic must never touch the public internet" → Direct Connect.**

**Peering is not transitive:** A↔B and B↔C does **not** give A↔C. **Transit Gateway** is the hub that solves it.

**Global Accelerator** — anycast IPs, routes over the AWS backbone for TCP/UDP performance.

---

### Checkpoint — Networking (answered after the session)

| # | Question | Correct answer |
|---|---|---|
| 1 | EU users served from EU for legal reasons | **Geolocation** — not latency |
| 2 | 10% of traffic to a new version | **Weighted** |
| 3 | Consistent latency, never the internet | **Direct Connect** |
| 4 | Apex record to an ALB | **Alias** — CNAME is invalid at apex |
| 5 | Worldwide fast static images | **CloudFront** |
| 6 | What OAC solves | Keeps S3 private; only CloudFront reads it, preventing CDN bypass |
| 7 | A↔B, B↔C — can A reach C? | **No** — peering isn't transitive. Use **Transit Gateway** |
| 8 | Three API Gateway types | **REST, HTTP, WebSocket** — HTTP is cheapest |

---

## Segment 5 — Integration & messaging

| Service | Model | Use |
|---|---|---|
| **SQS** | **queue — pull** | decouple, buffer, retry |
| **SNS** | **pub/sub — push** | fan-out notifications |
| **EventBridge** | event bus + rules | event-driven, content-based routing |
| **Step Functions** | state machine | multi-step orchestration |
| **Kinesis** | streaming | real-time analytics |
| **MQ** | ActiveMQ / RabbitMQ | lift-and-shift from on-prem |

### SQS vs SNS — the core distinction

| | **SQS** | **SNS** |
|---|---|---|
| Model | **pull** — consumer polls | **push** — subscriber notified |
| Consumers | one consumer per message | many subscribers per message |
| Use | work queue | notifications / fan-out |

**Standard SQS:** at-least-once delivery, best-effort ordering.
**FIFO SQS:** exactly-once, strict ordering, **lower throughput**.

**The fan-out pattern:** **SNS → one SQS queue per consumer.** Each consumer processes at its own pace, and a slow consumer doesn't block the others.

### EventBridge vs SNS

| | **SNS** | **EventBridge** |
|---|---|---|
| Routing | topic subscription | **rules matching event content** |
| Sources | your applications | AWS services, SaaS partners, custom buses |
| Use | simple fan-out | complex routing, event-driven architecture |

**"React to an EC2 state change" or "route by event detail" → EventBridge.**

### Step Functions

Visual state machine with retries, branching, waits and human approval. **Use when a workflow has multiple steps** — the alternative to chaining Lambdas in code.

**"Long-running workflow with retries and branching" → Step Functions.**

### Kinesis

**Data Streams** (custom consumers) · **Firehose** (deliver to S3/Redshift) · **Data Analytics** (SQL over streams) · **Video Streams**.

**"Ingest clickstream and analyse in real time" → Kinesis.**

---

## Segment 6 — Management & governance

| Service | Purpose |
|---|---|
| **CloudFormation** | AWS-native IaC — stacks, change sets |
| **CloudWatch** | metrics, logs, alarms, dashboards |
| **CloudTrail** | API audit — **who** did what |
| **AWS Config** | resource config history + compliance rules |
| **Systems Manager** | Patch Manager, **Session Manager**, Parameter Store, Run Command |
| **Trusted Advisor** | best-practice checks — **7 core on Basic** |
| **AWS Organizations** | multi-account, SCPs, consolidated billing |
| **Service Catalog** | approved product catalogue |
| **Control Tower** | automated landing zone |
| **Health Dashboard** | AWS service status |
| **AWS Artifact** | compliance reports + agreements |
| **Security Hub** | aggregated findings scorecard |

### CloudFormation vs Terraform

| | **CloudFormation** | **Terraform** |
|---|---|---|
| Scope | AWS only | **multi-cloud** |
| Language | YAML / JSON | HCL |
| State | AWS manages it | **you manage it** (S3 + DynamoDB lock) |
| Preview | **change sets** | `terraform plan` |

### SSM Session Manager — the modern access pattern

No public IP · **no open port 22** · no bastion host · **full session logging**.

**"Reach a private instance without a bastion" → Session Manager.**

### Organizations

Consolidated billing · **volume discounts aggregate** · RI/Savings Plan sharing · **SCPs** · OUs.

**The critical SCP rule:** an SCP is a **ceiling, never a grant**. It restricts the maximum possible permissions; IAM still has to allow the action. **SCPs don't apply to the management account.**

---

## Segment 7 — AI/ML awareness (CP level only)

| Service | Purpose |
|---|---|
| **SageMaker** | build/train/deploy ML models |
| **Bedrock** | foundation models via API |
| **Rekognition** | image/video — faces, labels, moderation |
| **Comprehend** | NLP — sentiment, entities, key phrases |
| **Polly** | text → speech |
| **Transcribe** | speech → text |
| **Textract** | extract text/tables from documents |
| **Translate** | language translation |
| **Personalize** | recommendations |
| **Forecast** | time-series forecasting |
| **Lex** | conversational bots |
| **Kendra** | intelligent search |

**The pattern the exam uses:**
- *"extract data from scanned invoices"* → **Textract**
- *"build a chatbot"* → **Lex**
- *"add product recommendations"* → **Personalize**
- *"analyse customer sentiment in reviews"* → **Comprehend**
- *"transcribe call recordings"* → **Transcribe**

**CP only asks "what is this for"** — not how to build with it.

---

## Scorecard — session 2

| Segment | Status |
|---|---|
| 4. Networking | taught + checkpointed (answers above) |
| 5. Integration | covered in reference — not individually checkpointed |
| 6. Management | covered in reference — not individually checkpointed |
| 7. AI/ML | covered in reference — awareness only |

**Domain 3 is now fully covered** (parts 1 and 2). The practice exam will show which services need a second pass.

## Five things to drill before practice exam #1

1. **Latency vs geolocation vs geoproximity** — speed vs country vs distance. Legal requirement → **geolocation**.
2. **Alias vs CNAME** — Alias works at the zone apex and is free; CNAME cannot be used at apex.
3. **OAC** — keeps S3 private so nobody bypasses CloudFront (and the WAF).
4. **SQS pull vs SNS push**, and the **SNS → multiple SQS** fan-out pattern.
5. **SCP = ceiling, never a grant** — and it doesn't apply to the management account.

---

## What I learned (in my own words)

*(fill in — 3-5 sentences: why does geolocation beat latency for a legal requirement? when would you use EventBridge instead of SNS? why is Session Manager better than a bastion?)*
