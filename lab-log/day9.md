# Day 9 — CP Domain 1 (Cloud Concepts) + Domain 4 (Billing, Pricing, Support)

**Date:** 2026-10-31
**Goal:** Cover the two "soft" CP domains — vocabulary-heavy, low hands-on.

**Exam weight:** Domain 1 = 24% · Domain 4 = 12%

---

## Segment 1 — What cloud computing is

> On-demand delivery of compute, database, storage and other IT resources **via the internet** with **pay-as-you-go pricing**.

| Characteristic | Meaning |
|---|---|
| **On-demand** | provision it yourself, in minutes |
| **Pay-as-you-go** | per hour/GB/request |
| **Elastic** | scale up and down with demand |

### The six advantages of cloud computing

| # | Advantage | Reasoning |
|---|---|---|
| 1 | **Trade capital expense for variable expense** | no upfront purchase; pay for consumption |
| 2 | **Benefit from massive economies of scale** | AWS buys in volume, passes savings on |
| 3 | **Stop guessing capacity** | scale to actual demand, not forecast |
| 4 | **Increase speed and agility** | resources in minutes, experiment cheaply |
| 5 | **Stop spending money running data centres** | no racks, power, cooling, space, staff |
| 6 | **Go global in minutes** | deploy to another continent in clicks |

### CapEx vs OpEx

| | **CapEx** | **OpEx (variable)** |
|---|---|---|
| What | large upfront purchase | per-use ongoing |
| Example | buy 20 servers | pay for 20 server-hours |
| Books | depreciating asset | operating cost |
| Risk | **wrong-sized and stuck** | adjust monthly |
| Cash flow | big outlay | small, predictable |

**The core insight:** CapEx commits you to a **capacity guess**; OpEx means you pay for **what actually happened**. Cloud shifts CapEx → OpEx, which explains advantages 1, 3 and 5.

**Memory grouping:** MONEY (1, 2, 5) · CAPACITY (3) · SPEED (4) · REACH (6).

---

## Segment 2 — IaaS / PaaS / SaaS

### The responsibility split

| Layer | **IaaS** | **PaaS** | **SaaS** |
|---|---|---|---|
| Application | **you** | **you** | provider |
| Data | **you** | **you** | provider |
| Runtime | **you** | provider | provider |
| Operating System | **you** | provider | provider |
| Virtualisation | provider | provider | provider |
| Servers/Storage/Network | provider | provider | provider |

### AWS examples

| Model | Services | You manage |
|---|---|---|
| **IaaS** | **EC2**, EBS, VPC | OS, patching, runtime, app, data |
| **PaaS** | **RDS**, Elastic Beanstalk, Lambda | app + data only |
| **SaaS** | WorkMail, Chime, Connect | nothing |

**Why EC2 = IaaS:** you get a VM — choose OS, install packages, patch it, secure it.
**Why RDS = PaaS:** you get a *database*, not a server. AWS runs the OS and engine patching.
**Why Lambda = PaaS:** upload a function; AWS handles everything below and scales to zero.

**Memory hook:**

```
IaaS = rent the kitchen        PaaS = kitchen + chef        SaaS = order the meal
```

**Containers (ECS/Fargate)** are sometimes called CaaS; for CP purposes treat as **closest to PaaS**.

### Key correction I made

When moving EC2 → RDS, **only the OS and runtime** change hands. Virtualisation and hardware were **already AWS's** — EC2 never gave you the hypervisor.

### SaaS tradeoff

In SaaS you genuinely **do not patch the OS** — that statement is true. What you give up is **control**: OS choice, customisation, vendor roadmap, data location, integration limits.

---

## Segment 3 — Deployment models & design principles

### Four deployment models

| Model | Meaning | Exam phrasing |
|---|---|---|
| **Cloud (public)** | everything on AWS | "moving to AWS" |
| **Hybrid** | AWS **+ own datacentre**, both in use | "some workloads on AWS, some on-prem" |
| **On-premises** | virtualisation in own DC | "must stay in our facility" |
| **Multi-cloud** | 2+ providers | "avoid single-vendor dependency" |

**"We're migrating to AWS" is NOT hybrid.** Hybrid requires **both environments actively serving traffic**.

### Four design principles

| Principle | Meaning | Practical shape |
|---|---|---|
| **Design for failure** | assume anything can fail | multi-AZ, health checks, retries |
| **Decouple components** | one failure doesn't cascade | SQS queues instead of direct calls |
| **Implement elasticity** | scale automatically | Auto Scaling, ECS service scaling |
| **Think parallel** | concurrent, not serial | fan-out |

**"Design for failure"** is the mindset shift: hardware *will* fail — build to **survive**, not to prevent.

**"Decouple"** is the most valuable reliability pattern:

```
Coupled:   API → payment service (down) → API errors too
Decoupled: API → queue → (service returns) → processes from queue
```

The API never blocks and never errors because the downstream is down.

---

## Segment 4 — Well-Architected Framework & CAF

### The distinction

| | **Well-Architected Framework** | **Cloud Adoption Framework** |
|---|---|---|
| Answers | is this **architecture** good? | is this **organisation** ready? |
| Focus | technical design | business + people + process |
| Unit | a workload | an organisation |
| Structure | **6 pillars** | **6 perspectives** |

**WAF = the building. CAF = the company moving in.**

### Well-Architected — 6 pillars

| # | Pillar | Question |
|---|---|---|
| 1 | **Operational Excellence** | can we run and improve this? |
| 2 | **Security** | is it protected? |
| 3 | **Reliability** | will it keep working when something fails? |
| 4 | **Performance Efficiency** | is it fast and right-sized? |
| 5 | **Cost Optimization** | are we wasting money? |
| 6 | **Sustainability** | what's our environmental impact? |

**Sustainability added 2021** — material saying "5 pillars" is out of date.

**Memory:** *"Ops Security Reliably Performs Cost-effectively, Sustainably."*

### Pillars conflict — the real understanding

| Tension | Example |
|---|---|
| **Reliability ↔ Cost** | multi-region replication multiplies cost |
| Performance ↔ Cost | bigger instances are faster, costlier |
| Security ↔ Ops Excellence | more controls, more friction |
| Sustainability ↔ Performance | bigger machines use more energy |

**Good architecture is the right balance, not maximising one pillar.**

**MY RECURRING ERROR: I twice answered "Performance Efficiency" when the right answer was "Reliability."**
**The test:** does this help when hardware *breaks*? → **Reliability**. Does it make things *faster*? → **Performance Efficiency**. A datacentre fire is a failure → Reliability. Always.

### Cloud Adoption Framework — 6 perspectives

| Area | Perspectives |
|---|---|
| **Business** | Business · People · Governance |
| **Technical** | Platform · Security · Operations |

**Rule of thumb:** *"staff lack skills"* or *"the team is resisting"* → **People** perspective.

---

## Segment 5 — Global infrastructure

### Hierarchy

```
Region (ap-south-1)
 ├── AZ a (aps1-az1)   ← separate power, cooling, network, flood risk
 ├── AZ b (aps1-az3)
 └── AZ c (aps1-az2)
Edge locations (400+)  ← CloudFront caching, NOT regions
Local Zones · Outposts · Wavelength Zones
```

### Region vs AZ vs Edge

| | **Region** | **AZ** | **Edge location** |
|---|---|---|---|
| What | geographic area | isolated datacentre(s) | CDN cache point |
| Count | ~36 globally | 3+ per region | 400+ |
| Purpose | residency, latency, compliance | **fault isolation** | **low-latency content** |
| Service | everything | everything | CloudFront, Route 53 |

**Distinguishing table:**

| Question says | Answer |
|---|---|
| "survive a datacentre failure" | **multiple AZs** |
| "serve users in Europe and Asia" | **multiple regions** |
| "fast global delivery of static content" | **edge locations / CloudFront** |
| "keep data in Germany" | **choose Frankfurt region** |

**MY ERROR:** I answered "regions" for global static content. **Correct: edge locations/CloudFront** — cache once, serve everywhere. Regions duplicate the *whole stack*, which is heavy for static files.

### ZoneName vs ZoneId — important detail

| Identifier | Example | Stable across accounts? |
|---|---|---|
| **ZoneName** | `ap-south-1a` | ❌ **no** — letters randomised per account |
| **ZoneId** | `aps1-az1` | ✅ **yes** — actual physical AZ |

**Why:** AWS shuffles the letter mapping per account so customers spread evenly instead of all picking "1a".

**Verified in my account (real output):**

```
ap-south-1a  →  aps1-az1
ap-south-1b  →  aps1-az3     ← b maps to az3
ap-south-1c  →  aps1-az2     ← c maps to az2
```

**Risk:** telling a colleague "use `ap-south-1a`" may land them in a *different* physical AZ — or worse, the same one you thought you'd avoided. **Coordinate by ZoneId.**

### Choosing a region — five factors

Latency · Compliance/data residency · Service availability · Cost · Sustainability

### Global vs regional services

| **Global** (`us-east-1` endpoint) | **Regional** |
|---|---|
| IAM, STS | EC2, ECS, RDS, Lambda |
| Route 53, CloudFront | VPC, ELB, CloudWatch |
| Cost Explorer, Budgets | S3 (mostly) |

**Proved in my own error message:** `arn:aws:ce:us-east-1:.../GetCostAndUsage` — Cost Explorer always uses `us-east-1` regardless of my region.

### Hands-on output

```
Regions enabled (describe-regions)             : 17
Regions total   (describe-regions --all-regions): 34
```

**The 17 vs 34 gap = opt-in regions.** Opt-in regions must be **manually enabled** (new regions, or different legal/security posture). Without `--all-regions` you see only what the account can actually use.

**Exam-relevant:** if a service "isn't available", check whether the *region* is enabled, not just whether the service launched there.

---

## Segment 6 — Pricing models

### What you pay for

| Driver | Billed by | Note |
|---|---|---|
| **Compute** | per hour or **per second** (Linux) | EC2, Lambda, Fargate |
| **Storage** | per **GB-month** | S3, EBS, snapshots |
| **Data transfer** | per GB | ⚠️ **IN free, OUT charged** |

### Four pricing principles

Pay as you go · Pay less when you reserve · Pay even less when you use more (tiers) · Pay even less as AWS grows

### Five compute options

| Model | Discount | Commitment | Reclaimable | Best for |
|---|---|---|---|---|
| **On-Demand** | 0% | none | ❌ | unpredictable, dev, variable |
| **Reserved** | up to ~72% | 1 or 3 yr | ❌ | steady state |
| **Savings Plans** | up to ~72% | 1 or 3 yr ($/hr) | ❌ | steady state, flexible |
| **Spot** | up to **90%** | none | ✅ **2-min warning** | batch, CI, stateless |
| **Dedicated Host** | — | — | ❌ | BYOL / per-socket licensing |

**RI types:** Standard (locked, biggest discount) · Convertible (change family/OS, smaller) · Scheduled (time windows).

**Savings Plans types:**

| Type | Applies to | Flexibility |
|---|---|---|
| **Compute SP** | EC2 + Fargate + Lambda, any family/region/OS | **highest** |
| **EC2 Instance SP** | one family, one region | deeper discount |

**Savings Plans are the modern recommendation** over RIs — same discount, more flexibility.

**Spot:** up to 90%, **2-minute warning**, from spare capacity. Good for batch/CI/stateless; **bad for databases and stateful apps**.

**Dedicated Host vs Dedicated Instance:** Host gives you the whole physical server (sockets/cores visible) — needed for **per-socket/BYOL licensing**. Dedicated Instance = hardware only you use, no hardware visibility.

### The utilisation rule — MY ERROR

**I chose Savings Plan for a dev environment running 9am–6pm weekdays.**

| Reality | |
|---|---|
| Hours used | 9am–6pm × 5 days = **45 h/week** |
| Hours in week | 168 |
| **Utilisation** | **~27%** |

A Savings Plan commits you to paying a **$/hour rate for every hour of 1–3 years** — including the 73% you never run.

**THE RULE:**

| Utilisation | Cheapest |
|---|---|
| **< ~60–70%** | **On-Demand** |
| **> ~70%** steady | Reserved / Savings Plans |
| Interruptible batch | Spot |

**"Flexible" means flexible about *what* you run it on — not about *whether* you pay.** The commitment is fixed.

### Data transfer

| Direction | Cost |
|---|---|
| **IN** | **free** |
| **OUT** to internet | charged per GB |
| Between AZs | charged per GB |
| Between regions | charged per GB |

"Huge transfer charges, barely any storage" = something is **serving data outward** (uncached static files, large API payloads, backups leaving AWS).

---

## Segment 7 — Free Tier & TCO

### Four categories of "free"

| Category | Duration | Examples |
|---|---|---|
| **Always Free** | forever | Lambda 1M req + 400k GB-s · DynamoDB 25 GB · SNS 1M publishes · CloudWatch 10 metrics + 10 alarms |
| **12 Months Free** | from signup | EC2 **750 h/month** t2/t3.micro · S3 5 GB · RDS 750 h · EBS 30 GB · CloudFront 50 GB out |
| **Trials** | 30 days – 2 months | **Inspector 90 days** · **SageMaker 2 months** · **GuardDuty 30 days** · Lightsail 1 month |
| **Never free** | no allowance at all | **NAT Gateway · load balancers · public IPv4 · EBS snapshots · unattached EIPs · cross-AZ transfer** |

**MY ERROR:** I answered Inspector/SageMaker/GuardDuty as "never free". They're **trials** — they have free windows. Never-free services have **no free window at all**.

### The 750-hour arithmetic

```
730 hours in an average month  (365 ÷ 12 × 24)
750 ÷ 730 = 1.027  → about ONE always-on instance
```

**Instance-hours is a pool, not a machine count:**

| Scenario | Hours | Billed |
|---|---|---|
| 1 instance, all month | 730 | ✅ 0 |
| **2 instances, all month** | **1,460** | **710** (1,460 − 750) |
| 1 instance, 500 h | 500 | ✅ 0 |
| 3 instances × 250 h | 750 | ✅ 0 (exactly at limit) |

**Wrong mental model:** "750 instances". **Right:** "750 hours of runtime".
Only **t2.micro / t3.micro** qualify. Per region, per month, resets monthly.

### TCO — Total Cost of Ownership

Hidden on-prem costs people forget:

| Cost | Forgotten? |
|---|---|
| Server hardware | obvious |
| **Power** | often |
| **Cooling** | often |
| **Floor space / rent** | often |
| **Network equipment** | often |
| **Staff to run it** | often |
| **Hardware refresh every 3–5 yrs** | often |
| **Over-provisioning for peak** | almost always |

**The comparison tools:**

| Tool | Purpose |
|---|---|
| **AWS Pricing Calculator** | estimate a **planned** architecture |
| **Migration Evaluator** (ex-TSO Logic) | discover on-prem inventory, compare to AWS |
| **Cost Explorer** | **historical** spend + forecast |

---

## Segment 8 — Organizations & cost tools

### AWS Organizations

```
Management account
 ├── OU: Production     → prod-app, prod-db
 ├── OU: Development    → dev-1, dev-2
 └── OU: Sandbox        → experiments
```

| Term | Meaning |
|---|---|
| **Management account** | root of the org |
| **Member account** | any other account |
| **OU** | folder for grouping accounts; policies attach to OUs |
| **SCP** | Service Control Policy — a guardrail |

### Four benefits

| # | Benefit | Mechanism |
|---|---|---|
| 1 | **Consolidated billing** | one invoice |
| 2 | **Volume discounts** | usage **aggregates** → hits tiers faster |
| 3 | **RI / SP sharing** | discounts bought in one account apply org-wide |
| 4 | **Central governance** | SCPs, central CloudTrail |

### SCP — the critical rule

**An SCP NEVER grants permission. It only restricts.**

```
SCP:        deny ec2:*               ← ceiling (max possible)
IAM:        allow ec2:RunInstances    ← floor (actual granted)

Effective = overlap = NOTHING → CANNOT launch
```

```
Request ──▶ [ SCP gate: deny ] ──▶ BLOCKED (IAM gate never reached)
```

**BOTH must allow.** An SCP Deny overrides every IAM Allow — same explicit-deny-wins principle as Day 8.

**SCPs do NOT apply to the management account** — deliberate, so you can never lock yourself out of the org entirely.

### Cost tools by granularity

| Tool | Purpose | Detail |
|---|---|---|
| **AWS Budgets** | thresholds + alerts (+ auto-actions) | coarse |
| **Cost Explorer** | visualise, filter, **forecast** | daily/monthly, 12-month history |
| **CUR** (Cost and Usage Report) | **every line item** → S3 | **hourly, resource-level** |
| **Cost Anomaly Detection** | ML baseline, deviation alerts | automatic |
| **Cost Allocation Tags** | split bill by team/project | user-defined |

**Order:** Budgets (alarm) → Cost Explorer (analysis) → **CUR (forensic detail)**.

**MY ERROR:** I answered Cost Explorer for "per-instance per-hour detail". **Cost Explorer aggregates daily** and can't identify a specific resource. **CUR is the only hourly, resource-level source.**

### Budget types

Cost · Usage · RI utilisation · RI coverage · Savings Plans

**Budget actions** can automatically apply an SCP, stop instances, or notify when breached — enforcement, not just alerting.

### Cost allocation tags — two-step process

```
1. Tag the resource           → Project: website on 40 resources
2. ACTIVATE the tag           → Billing console → Cost allocation tags → Activate
```

**Creating the tag is not enough.** It must be activated, and takes up to 24 h to appear in reports. **MY ERROR:** I left this blank.

### Anomaly detection vs budget

| Scenario | Monthly budget ($500) | Anomaly detection |
|---|---|---|
| Normal $10/day, spikes to $400/day | ❌ under budget | ✅ fires in hours |
| Forgotten instance type | ❌ creeps up | ✅ fires on the change |

**Budget** = "have I spent more than X?" · **Anomaly detection** = "is spending behaving unusually?"

---

## Segment 9 — Support plans & Trusted Advisor

### Five plans

| Plan | Price | Production-down response | Channel | Trusted Advisor |
|---|---|---|---|---|
| **Basic** | **free** | none | billing only | **7 core checks** |
| **Developer** | ~$29/mo | **12 h** (impaired) | business-hours email | 7 core checks |
| **Business** | ~$100/mo | **1 h** | **24/7 phone/chat/email** | **full checks** |
| **Enterprise On-Ramp** | ~$5,500/mo | **30 min** (business-critical) | 24/7 | full |
| **Enterprise** | ~$15,000/mo | **15 min** (business-critical) | 24/7 | full + **dedicated TAM** |

### Two separate ladders — keep them apart

```
Severity ladder : Critical > Urgent > High > Normal > Low
Plan ladder     : Enterprise > On-Ramp > Business > Developer > Basic
```

**MY ERROR:** I ranked the severity ladder when asked to rank the plans.

### Severity response times

| Severity | Business | Enterprise |
|---|---|---|
| **Critical** (business-critical down) | 1 h | **15 min** |
| **Urgent** (production down) | 1 h | 1 h |
| **High** (production impaired) | 4 h | 4 h |
| **Normal** (system impaired) | 12 h | 12 h |
| **Low** (general guidance) | 24 h | 24 h |

**Only the Critical row differs.** Enterprise's real differentiators are the **TAM** and **Concierge**.

### TAM vs IEM — MY ERROR

| Feature | What | Plan |
|---|---|---|
| **TAM** | **ongoing, named** engineer who knows your architecture | **Enterprise** (dedicated) / On-Ramp (pool) |
| **IEM** | AWS engineers join a **specific event** (launch, migration, peak) | Business+ (extra fee) |

**The test:** *"who do I call every week?"* → **TAM (Enterprise)**. *"who helps with this one launch?"* → **IEM (Business+)**.

**"Named engineer who understands their architecture" = dedicated TAM = Enterprise.**

### Trusted Advisor

Five categories: **Cost Optimization · Performance · Security · Fault Tolerance · Service Quotas**

| Plan | Checks |
|---|---|
| **Basic / Developer** | **7 core checks only** |
| **Business and above** | **all checks** + weekly notification |

**The 7 core checks** (all about **exposure**):

1. S3 bucket permissions (public access)
2. Security groups — unrestricted ports (22/3389 open to 0.0.0.0/0)
3. IAM use (are you using root?)
4. MFA on root account
5. EBS public snapshots
6. RDS public snapshots
7. Service limits / quotas

**So a free-tier startup CAN find out if their S3 bucket is public** — that's core check #1 on the Basic plan.

**Confirmed in my own account:** `AWSServiceRoleForTrustedAdvisor` exists — the role AWS created so Trusted Advisor can read resources and run checks.

### Other features

| Feature | Plans |
|---|---|
| Infrastructure Event Management | Business+ (fee) |
| Concierge | Enterprise only |
| AWS Support API | Business+ |
| Third-party software support | Business+ |

---

## Scorecard — what I got right and wrong

| Topic | Result |
|---|---|
| Six advantages, CapEx/OpEx | ✅ |
| IaaS/PaaS/SaaS | ✅ (one nuance: EC2→RDS only moves OS+runtime) |
| Deployment models | ✅ |
| Design principles | ✅ |
| WAF 6 pillars (list) | ✅ |
| **Reliability vs Performance pillar** | ❌ **twice** |
| CAF 6 perspectives | ✅ |
| Region/AZ/Edge | ✅ |
| **Edge locations for static content** | ❌ chose regions |
| ZoneName vs ZoneId | ✅ |
| Opt-in regions (17 vs 34) | ✅ |
| **On-Demand vs Savings Plan at 27% util** | ❌ chose Savings Plan |
| Spot / Dedicated Host / Data transfer | ✅ |
| Free Tier 750-hour arithmetic | ✅ |
| **Free Tier categories (trial vs never-free)** | ❌ named trials |
| TCO hidden costs | ✅ |
| Pricing Calculator vs Cost Explorer | ✅ |
| **SCP + IAM both must allow** | ✅ (concept right, verdict omitted) |
| **CUR for per-resource hourly detail** | ❌ chose Cost Explorer |
| **Tag activation** | ❌ left blank |
| Anomaly detection vs budget | ⚠️ partial |
| Support plan tiers | ✅ |
| **TAM vs IEM** | ❌ confused them |
| **Plan ladder vs severity ladder** | ❌ answered severity |

## Three things to drill before the practice exam

1. **Reliability vs Performance Efficiency** — failure vs speed. Datacentre fire = Reliability.
2. **On-Demand vs Reserved** — utilisation under ~70% means On-Demand.
3. **CUR vs Cost Explorer** — hourly per-resource detail only exists in CUR.
4. **TAM (ongoing, Enterprise) vs IEM (one event, Business+).**
5. **SCP is a ceiling — never grants; both layers must allow.**

---

## What I learned (in my own words)

*(fill in — 3-5 sentences: why is "the allowance is a quantity of usage" the key idea for both Free Tier and Savings Plans? why can an SCP block something IAM allows? why does Reliability keep getting confused with Performance?)*
