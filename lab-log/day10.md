# Day 10 — CP Domain 2: Security & Compliance (30%)

**Date:** 2026-11-06
**Goal:** Cover the heaviest-weighted CP domain. ~40% revision from Days 3, 7 and 8.

**Exam weight:** Domain 2 = 30%

---

## Segment 1 — Shared Responsibility Model

**The single most-tested concept in CP.**

```
AWS  =  security OF the cloud    → hardware, facilities, hypervisor, managed-service internals
You  =  security IN the cloud    → your data, your config, your access, your guest OS
```

### The line moves by service

| Service | AWS manages | **You** manage |
|---|---|---|
| **EC2** (IaaS) | hardware, hypervisor, network | **guest OS patching**, app, data, SG rules, IAM |
| **RDS** (PaaS) | hardware, **OS**, **engine patching**, backups | data, DB users, network access, encryption choice |
| **S3** | infrastructure, durability | **bucket policy, public-access settings**, encryption choice, IAM |
| **Lambda** | everything below the function | **your code**, IAM role, env vars, dependencies |
| **DynamoDB** | infrastructure, engine, scaling | data, IAM, encryption choice |

### The four traps

| Trap | Truth |
|---|---|
| "AWS patches the OS on EC2" | ❌ **False.** AWS patches the **hypervisor**. Guest OS is 100% yours |
| "RDS means AWS handles all security" | ❌ AWS does OS + engine. You do network access, DB users, encryption |
| "S3 buckets are private so AWS secures data" | ❌ Private by default, but **you** can make them public. Leaks are customer responsibility |
| "Using AWS makes us compliant" | ❌ AWS is compliant **as a provider**. **Your workload's compliance is yours** |

### Three control categories

| Category | Who |
|---|---|
| **Inherited** | AWS entirely — physical, environmental |
| **Shared** | both — patch management, configuration management |
| **Customer-specific** | **you alone** — data classification, IAM, application security |

### Why it matters

Every major AWS incident is a customer-side failure: public buckets, exposed keys, unpatched EC2, `0.0.0.0/0` on 22. **The infrastructure is rarely the problem — configuration is.**

**My own account is the example:** no password policy, no MFA on `Athena`. AWS provided the controls; the configuration is mine.

**Checkpoint score: 5/5.**

---

## Segment 2 — IAM deep: root, MFA, credentials

### The four root account rules

| Rule | Why |
|---|---|
| 1. Never use root for daily work | no guardrail applies to root — no SCP, no boundary |
| 2. Enable MFA on root | the one identity that cannot be restricted |
| 3. No access keys on root | permanent + unlimited — the biggest credential risk |
| 4. Use only for account-level tasks | billing, closing the account, support plan, restoring an IAM admin |

**Legitimate root use I performed:** attaching `CloudWatchLogsReadOnlyAccess` to `Athena` in the console — `Athena` has read-only IAM and cannot attach policies to itself. That is exactly the textbook case.

### My account's real gaps

| Check | Status |
|---|---|
| Root MFA | ✅ |
| **IAM user MFA on `Athena`** | ❌ **none** |
| **Account password policy** | ❌ **none** (`NoSuchEntity`) |
| Access keys | 1 active, created 20 Oct |
| Least privilege | ✅ 4 scoped read-only policies |

### What MFA actually protects

| MFA protects | Does NOT protect |
|---|---|
| Console sign-in with password | ✅ |
| | ❌ **API calls with access keys** |

Adding MFA to `Athena` would **not** protect the CLI. Options to protect API access:

1. **MFA-conditional policy** — `Condition: {"Bool": {"aws:MultiFactorAuthPresent": "true"}}`
2. **Roles instead of keys** — STS temporary credentials
3. **GitHub OIDC → role** — session 16

**Without a policy condition, the API never asks for MFA.**

### MFA device types

| Type | Note |
|---|---|
| Virtual (Authenticator, Authy, 1Password) | free, most common |
| Hardware TOTP (Gemalto, SurePassID) | physical token |
| **FIDO security key (YubiKey)** | **phishing-resistant, strongest** |
| SMS | ⚠️ weakest — SIM-swap; **not supported for root** in most regions |

### Password policy — recommended

14+ chars · upper/lower/numbers/symbols · allow user change · 90-day expiry (debated; NIST discourages forced rotation) · prevent reuse of 24.

**Mine has none of this** — the console would accept `password`.

### The 14 IAM best practices — the tested three

**Lock away root · grant least privilege · use roles not keys.** Also: individual users, use groups, MFA, rotate credentials, remove unused, conditions (IP/MFA/TLS), monitor with CloudTrail.

### The four auditing tools

| Tool | Answers |
|---|---|
| **Credential Report** | every user's **MFA status, key age, password age, last login** (CSV) |
| **Access Advisor** | which services a user **actually used**, and when last accessed |
| **IAM Access Analyzer** | which resources are shared **outside** the account |
| **CloudTrail** | **who called what API, when, from where** |

**Access Advisor is the least-privilege tool** — it shows unused permissions you can remove. **Least privilege is a review cycle, not a one-time decision.**

---

## Segment 3 — Network security

### The five differences

| | **Security Group** | **NACL** |
|---|---|---|
| Level | instance / ENI | **subnet** |
| Stateful | ✅ | ❌ |
| Rules | **Allow only** | Allow **and Deny** |
| Evaluation | union (any match) | **numbered, first match wins** |
| Default | deny in / allow out | allow all |

### Stateful vs stateless

**SG:** inbound allowed → return traffic auto-permitted.
**NACL:** every packet judged independently.

```
Client:54321 → Server:443      inbound 443 rule
Server:443 → Client:54321      NEW packet → needs its OWN outbound rule
```

**Ephemeral ports 1024–65535.** *"I opened 443 on the NACL, why doesn't HTTPS work?"* → **return traffic blocked.**

### The layer order

```
Internet → IGW → route table → NACL → security group → instance → app
```

**Every layer must permit. Debug order: routes → NACL → SG** (widest first). A block anywhere looks identical: "can't connect."

### VPC security features

| Feature | Purpose |
|---|---|
| **Private subnet** | no IGW route — unreachable from internet |
| **NAT Gateway** | out-only reach; ⚠️ never free |
| **VPC Flow Logs** | **metadata** (src, dst, port, ACCEPT/REJECT) — no payload |
| **VPC Endpoint / PrivateLink** | reach AWS services without the internet |
| **Bastion** | public jump box; needs public IP + port 22 |
| **SSM Session Manager** | shell with **no open port, no bastion, full session logging** |
| **Network Firewall** | VPC-level stateful inspection |
| **SG referencing** | `source = sg-abc123` instead of a CIDR |

### Flow Logs for debugging

| Flow log shows | Meaning |
|---|---|
| `REJECT` at NACL | subnet-level block |
| `ACCEPT` then nothing | SG or app blocked it |
| nothing at all | route problem — packet never arrived |

### Bastion vs Session Manager

| | Bastion | Session Manager |
|---|---|---|
| Public IP | ✅ | ❌ |
| Port 22 open | ✅ | ❌ |
| SSH keys | ✅ | ❌ |
| Audit trail | partial | ✅ full recording |
| Cost | EC2 instance | free |

**Best-practice answer:** *"SSM Session Manager — no open port, no bastion, full session logging."*

### SG referencing beats CIDR

`source = sg-abc123` follows the resource, survives IP/AZ changes, and needs no hardcoded subnet ranges. **Used in session 13** — the ALB's SG is the source for the ECS task's SG.

---

## Segment 4 — Encryption

### Two states

| State | Meaning |
|---|---|
| **At rest** | on disk — S3, EBS, RDS, snapshots |
| **In transit** | over a network — TLS, VPN, DB connections |

Independent. Compliance usually demands both.

### S3's four options at rest

| Option | Who holds the key | Audit trail of key use | Use when |
|---|---|---|---|
| **SSE-S3** | AWS | ❌ | ✅ **default since Jan 2023** |
| **SSE-KMS** | KMS, **you control policy** | ✅ **CloudTrail logs every use** | audit needed |
| **SSE-C** | **you**, per request | ❌ | AWS must never hold it |
| **Client-side** | you, before upload | ❌ | maximum control |

**"Prove via audit logs who decrypted what" → SSE-KMS.** The only option with a CloudTrail trail of key usage.

### KMS concepts

| Concept | Meaning |
|---|---|
| CMK | the key object |
| AWS managed key | AWS creates it, you don't control policy |
| Customer managed key | you create it, control policy/rotation/grants |
| Key policy | who may use and administer |
| Rotation | yearly, optional, recommended |
| Grants | temporary use permission without changing the policy |

### Envelope encryption

```
1. KMS encrypts a DATA KEY
2. The data key encrypts your data (any size)
3. The encrypted data key is stored with the data
4. To read: KMS decrypts the data key, then decrypt the data
```

**Why not encrypt data directly with KMS:**

| Reason | Detail |
|---|---|
| **4 KB limit** | KMS can't take a 5 GB object |
| **Network cost** | all data would traverse to KMS and back |
| **Throttling** | request quotas would be exhausted |

**The master key never leaves KMS.**

### Encryption in transit

TLS/HTTPS · **ACM (free certs for ALB/CloudFront/API GW)** · VPN · **PrivateLink** · SSH · TLS on RDS (`sslmode=require`).

**Enforced with a condition key:**

```json
{"Effect": "Deny", "Action": "s3:*", "Resource": "*",
 "Condition": {"Bool": {"aws:SecureTransport": "false"}}}
```

`aws:SecureTransport` is a **boolean condition** — `true` when the request used SSL/TLS. Put it in a **Deny** to reject non-TLS requests.

### Defaults by service

| Service | Default |
|---|---|
| **S3** | ✅ SSE-S3 since Jan 2023 |
| EBS | ⚠️ account-level default can be enabled |
| **RDS** | ❌ **must be set at creation** |
| DynamoDB | ✅ always encrypted |
| CloudTrail logs | ✅ SSE-S3 |
| Lambda env vars | ✅ KMS |
| EFS | ⚠️ at creation |

### The RDS trap

**You cannot encrypt an existing unencrypted RDS instance.**

```
1. Snapshot the unencrypted instance
2. COPY the snapshot with encryption enabled   ← does the encryption
3. Restore a new instance from the encrypted snapshot
4. Repoint the application
```

**Encryption is a creation-time decision for RDS and EFS.** S3 and EBS can change after the fact.

**Checkpoint score: 6.5/7.**

---

## Segment 5 — Detection services

| Service | Answers | Analogy |
|---|---|---|
| **CloudTrail** | **who** called what API, when, from where | CCTV |
| **AWS Config** | **what did this resource look like**, and when did it change | asset register |
| **GuardDuty** | **is something behaving maliciously** | intruder alarm |
| **Inspector** | **what vulnerabilities exist** | CVE scan |
| **Macie** | **where is sensitive data in S3** | data classifier |

**Memory hook:** *Trail = who · Config = what · Guard = threat · Inspector = vuln · Macie = PII.*

### All five denied in my account

```
cloudtrail:DescribeTrails     AccessDenied
guardduty:ListDetectors       AccessDenied
inspector2:BatchGet...        AccessDenied
macie2:GetMacieSession        AccessDenied

aws config describe-...       ParamValidation: invalid choice 'config'
```

**Two lessons:** least privilege means you can't inspect the security services themselves; and **`aws config` doesn't exist — it's `aws configservice`.** A real CLI quirk.

### CloudTrail

| Concept | Detail |
|---|---|
| Event history | **90 days**, free, per-region |
| **Trail** | delivers events to **S3** → retention set by S3 lifecycle |
| Multi-region trail | one trail, all regions — standard |
| Organization trail | one trail for every account |
| Log file validation | digests proving logs untampered |
| **Management events** | control plane — **free for one trail** |
| **Data events** | object level (`GetObject`) — **high volume, charged** |

**Neither blocks nor detects. It records.**

**I got this wrong in the checkpoint** — asked how to get 2 years of history, I answered "Config + CloudTrail". **The answer is a CloudTrail trail delivering to S3** (with an S3 lifecycle for 2 years, or Glacier after 90 days). Config records *resource configuration*, not API events.

### AWS Config

Configuration recorder → configuration items (snapshots) → rules → COMPLIANT/NON_COMPLIANT → optional SSM Automation remediation.

**The question it answers that CloudTrail can't:**
> *"Was this SG open to 0.0.0.0/0 last Tuesday, or did someone change it Wednesday?"*

**CloudTrail = who. Config = what it looked like.**

**Cost:** not free — charged per configuration item recorded and per rule evaluation.

### GuardDuty

Analyses **CloudTrail + VPC Flow Logs + DNS logs** with ML and threat intelligence. **Agentless.**

Finding types: recon, unauthorised access, crypto mining, **credential compromise** (key used from two continents in an hour), S3 anomalies.

**30-day free trial**, then per GB analysed. **Does not block** — findings → console + EventBridge.

**The killer pattern:** GuardDuty "unusual credential use" → EventBridge → Lambda → `iam:UpdateAccessKey Status=Inactive` → SNS.

### Inspector

| Scans | What |
|---|---|
| EC2 | OS package CVEs (via SSM agent) |
| ECR images | base-image and dependency CVEs |
| Lambda | code dependencies |

**15-day free trial.**

**GuardDuty vs Inspector:** *attacking me now* (runtime, behaviour) vs *what's vulnerable in my build* (scan, CVEs).

### Macie

PII, financial data, credentials, custom regex — in S3, ML-based. **30-day trial**, then **per GB scanned** (continuous, so scope with bucket filters).

**Question it exists for:** *"does any bucket hold PII we don't know about?"*

### The comparison that wins interviews

| Question | Service |
|---|---|
| Who deleted the bucket at 3am? | **CloudTrail** |
| Was this SG open last week, and who opened it? | **Config** + **CloudTrail** |
| Is my EC2 mining crypto? | **GuardDuty** |
| Which images have CVEs? | **Inspector** |
| Does any bucket hold card numbers? | **Macie** |

**Checkpoint score: 6/7.**

---

## Segment 6 — Protection services

| Service | Protects against | Layer |
|---|---|---|
| **Shield Standard** | DDoS — **free, automatic, every account, no action needed** | L3/L4 |
| **Shield Advanced** | DDoS — paid: 24/7 response team, cost protection, WAF included | L3/L4 |
| **WAF** | SQL injection, XSS, bad bots, rate limiting | **L7** |
| **Firewall Manager** | central WAF/SG/Shield management **across accounts** | management |
| **Network Firewall** | VPC-level stateful inspection | L3/L4 |

### Shield vs WAF — the exam distinction

| | **Shield** | **WAF** |
|---|---|---|
| Attack | **volumetric DDoS** — flood the pipe | **application attacks** — exploit requests |
| Layer | 3/4 | **7 (HTTP)** |
| Example | 500 Gbps of junk | SQL injection in a form |
| Cost | **Standard free**, Advanced paid | per rule + per request |

**Shield Standard is on by default — you don't enable it.** Most people don't know that.

**Firewall Manager requires AWS Organizations.**

---

## Segment 7 — Secrets

| | **Secrets Manager** | **SSM Parameter Store** |
|---|---|---|
| Cost | **$0.40/secret/month** + calls | **Standard: free** (≤10,000 params) |
| **Automatic rotation** | ✅ **built-in Lambda rotation** (RDS, Redshift, DocumentDB) | ❌ build it yourself |
| Cross-account | ✅ | ❌ limited |
| Versioning | ✅ staging labels (AWSCURRENT/AWSPREVIOUS) | ✅ basic |
| Encryption | KMS always | KMS for `SecureString` only |
| Max size | 64 KB | 4 KB standard / 8 KB advanced |

**The one-line rule:**
> **Need rotation, or a database password → Secrets Manager. Cheap config values → Parameter Store.**

**Rotation mechanism:** Secrets Manager triggers a Lambda every N days → generates a new password → updates the database → stores the new value. **That machinery is what you're paying for.**

### Never put secrets in Terraform state

```hcl
resource "aws_db_instance" "db" {
  password = "hunter2"     # 🔴 now in terraform.tfstate, plaintext, forever
}
```

**The real risk is `terraform.tfstate`, not the `.tf` file.** State stores every value in plaintext by design. Commit it once and the secret lives in **git history permanently** — you can only rewrite history and assume compromise.

**The fix — reference, don't embed:**

```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db/password"
}
```

**Used in session 10** — the Terraform secrets fold.

**Checkpoint score: 6/6.**

---

## Segment 8 — Compliance

### The core principle

> **AWS is compliant as a _provider_. Your workload's compliance is _yours_.**

You **inherit** infrastructure controls. You do **not** inherit a certificate for your application.

**Exam phrasing:** *"build a HIPAA-compliant workload on AWS"* → **sign a BAA with AWS, then implement your own controls.**

### AWS Artifact — the tool to memorise

| | |
|---|---|
| **Artifact Reports** | SOC, ISO, PCI attestations — downloadable |
| **Artifact Agreements** | sign agreements, e.g. the **HIPAA BAA** |
| **Cost** | **free** |

**"Obtain AWS's compliance documentation" → Artifact.** That's the whole answer.

### The standards

| Standard | Note |
|---|---|
| SOC 1 | financial reporting controls |
| **SOC 2** | security/availability/confidentiality — **most relevant to cloud workloads** |
| SOC 3 | public summary of SOC 2 |
| PCI DSS | card data — AWS is compliant, **your cardholder environment is your scope** |
| HIPAA | US health — **requires a signed BAA** |
| **GDPR** | ⚠️ a **regulation, not a certification** — no certificate exists |
| ISO 27001 | information security management |
| FedRAMP | US government **authorisation** of AWS services, not something you apply for |

**Two traps:** GDPR is a law (nobody "gets GDPR certified"); FedRAMP authorisation belongs to AWS's services.

### Compliance tooling

| Tool | Purpose |
|---|---|
| **Artifact** | download reports; sign agreements |
| **Config + conformance packs** | bundled rules mapped to a standard |
| **Audit Manager** | automates evidence collection |
| **Security Hub** | **aggregates GuardDuty/Inspector/Config/Macie findings into one scorecard** against CIS, PCI, AWS FSBP |
| KMS / CloudHSM | key control |

### My honest sentence

> *"AWS holds SOC 1/2/3, ISO 27001, PCI DSS and FedRAMP authorisations for its services. Those cover the infrastructure. My workload's compliance — data classification, access control, encryption, retention — is my responsibility."*

---

## Segment 9 — Pen testing & incident response

### The pen-testing policy

| ✅ Allowed without approval | ❌ Prohibited |
|---|---|
| Testing **your own** EC2, RDS, CloudFront, API GW, Lambda, S3, ECS | **DDoS simulation on any AWS resource — including your own** |
| Port scanning your own instances | **DNS zone walking** via Route 53 |
| Protocol fuzzing your own endpoints | Port flooding / request flooding |
| Testing your own web applications | Testing **other customers'** resources |
| | Physical attacks on AWS facilities |

**The one I got half-wrong:** pen-testing your own EC2 is ✅ **allowed**, but **DDoSing it is ❌ prohibited** — even on your own app. Use a simulated load test instead (session 14's `hey` is fine; that's load, not DDoS).

**Reporting abuse from an AWS IP:** the AWS abuse team (`abuse@amazonaws.com`).

### NIST incident response — four phases

```
1. Preparation                        → runbooks, alarms, IAM, contacts
2. Detection & Analysis               → GuardDuty, CloudWatch, CloudTrail
3. Containment, Eradication & Recovery → isolate, remove, restore
4. Post-Incident Activity             → post-mortem, fix root cause
```

**I missed phase 4 in the checkpoint.** Phases 1–3 are built by session 32; phase 4 is the incident report and game day.

### AWS services for IR

| Service | Role |
|---|---|
| **CloudTrail** | the timeline — what happened |
| **GuardDuty** | the detection signal |
| **EventBridge** | routes findings to automated responses |
| **Lambda** | the automated action |
| **SSM Automation** | runbooks executed automatically |
| **Security Hub** | aggregate view across accounts |
| **AWS Config** | config before/after |

### The automated containment pattern

```
GuardDuty: "credentials used from unusual location"
  → EventBridge rule matches
    → Lambda runs
      → iam:UpdateAccessKey Status=Inactive
        → SNS notifies the team
```

**Containment in seconds, not hours.** This is also the pattern session 31 evaluates — an AI proposing remediation against a known-correct answer.

### What AWS does NOT do

Deciding what's an incident · calling people at 3am · root-cause analysis · deciding to roll back · **notifying customers (GDPR 72h)** · restoring your data.

**Shared responsibility, applied to incidents.**

**Checkpoint score: 4.5/7.**

---

## Scorecard — all nine segments

| # | Segment | Score | Issue |
|---|---|---|---|
| 1 | Shared responsibility | **5/5** | — |
| 2 | IAM deep | — | checkpoint skipped (Day 8 revision) |
| 3 | Network security | — | checkpoint skipped (Day 8: 4/4 there) |
| 4 | Encryption | **6.5/7** | `aws:SecureTransport` is a *condition*, not a transport action |
| 5 | Detection | **6/7** | ❌ said "Config + CloudTrail" for 2-year history — it's a **trail → S3** |
| 6 | Protection | **6/6** | — |
| 7 | Secrets | **6/6** | — |
| 8 | Compliance | **4.5/7** | ❌ didn't name **AWS Artifact** · ❌ DDoS *is* prohibited on your own app |
| 9 | Incident response | (same set) | ❌ missed NIST phase 4: **Post-Incident Activity** |

## Four things to drill before the practice exam

1. **CloudTrail vs Config** — events (who) vs resource state (what). 2-year retention = **trail → S3**, never Config.
2. **AWS Artifact** — the only answer for "get AWS's compliance reports" or "sign the HIPAA BAA". Free.
3. **DDoS is prohibited even on your own resources.** Pen-testing your own infra is allowed; DDoS is not.
4. **NIST IR phases** — all four, including **Post-Incident Activity**.

---

## What I learned (in my own words)

*(fill in — 3-5 sentences: why does the shared responsibility line move between EC2 and RDS? what's the practical difference between CloudTrail and Config when investigating an incident? why isn't "we're on AWS" a compliance answer?)*
