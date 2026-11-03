# Day 8 — AWS Depth: IAM, Networking Security, CloudWatch

**Date:** 2026-10-31
**Goal:** Understand *why* AWS permissions work the way they do, not just how to list resources.

**Account:** 977099009814 · user `Athena` · region `ap-south-1`

---

## Part A — The IAM model

### My actual setup

```
User    : Athena
Policies: AmazonEC2ReadOnlyAccess
          IAMReadOnlyAccess
          AmazonS3ReadOnlyAccess
Groups  : (none)                    ← policies attached directly to the user
Roles   : AWSServiceRoleForResourceExplorer
          AWSServiceRoleForSupport
          AWSServiceRoleForTrustedAdvisor
```

### The four objects

| Object | What it is | Can it log in? |
|---|---|---|
| **User** | Long-lived identity with credentials | ✅ yes |
| **Group** | Container for users — attach policies once, apply to many | ❌ not an identity |
| **Role** | Permission set **assumed temporarily** | ✅ via assumption, not login |
| **Policy** | The JSON document | ❌ it's a document |

### Two observations about my setup

**1. Policies attached directly to the user, not via a group.**

Works for one person; doesn't scale. With 20 engineers you'd attach policies 60 times instead of 3. Standard practice:

```
Athena ──member of──▶ [DevOpsReadOnly] ──attached──▶ 3 policies
```

**2. The three roles are service-linked roles.**

AWS created them automatically when I enabled those services. `AWSServiceRoleForTrustedAdvisor` is how Trusted Advisor gets permission to read my resources.

**Key insight: a role has no password and no access key.** Something assumes it and receives temporary credentials. That's why roles are preferred — nothing long-lived to leak.

---

## Part B — Policy JSON anatomy

```bash
aws iam get-policy-version \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --version-id v1 --profile portfolio \
  --query PolicyVersion.Document --output json
```

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:Get*", "s3:List*"],
            "Resource": "*"
        }
    ]
}
```

| Field | Value | Meaning |
|---|---|---|
| **Version** | `2012-10-17` | ⚠️ **policy language version**, not a revision number. Unchanged for a decade. |
| **Statement** | `[...]` | array — many statements allowed |
| **Effect** | `Allow` | or `Deny`. Nothing else valid |
| **Action** | `["s3:Get*","s3:List*"]` | `service:operation`, `*` = wildcard |
| **Resource** | `"*"` | everything |

### What it grants, and what it doesn't

```
Grants : s3:Get*  → GetObject, GetBucketPolicy, GetBucketAcl...
         s3:List* → ListBucket, ListAllMyBuckets...

Denies : s3:PutObject, s3:DeleteObject, s3:CreateBucket, s3:PutBucketPolicy
```

**It's a whitelist.** Anything not listed is denied by default — no explicit Deny needed.

### When `"Resource": "*"` is acceptable

Here it's fine because **the actions are already read-only**. The worst case is reading data you can access anyway.

It becomes dangerous when paired with broad actions:

```json
{"Effect":"Allow","Action":"*","Resource":"*"}   ← full admin
```

**Rule:** broad `Resource` only when `Action` is narrow. Never both.

### Priority order

```
Explicit Deny  >  Explicit Allow  >  Implicit Deny (default)
```

An explicit `Deny` anywhere — policy, boundary, SCP — overrides every Allow in the account. That's how guardrails work.

---

## Part C — Security groups vs NACLs

### My real config

```
VPC     vpc-0409bd0af26230be4   172.31.0.0/16   default
Subnets subnet-041c0ad7394519fd1  172.31.0.0/20   ap-south-1b
        subnet-0a655b690b17577bb  172.31.16.0/20  ap-south-1c
        subnet-01e7d017da42f45d0  172.31.32.0/20  ap-south-1a
SG      sg-007e5b550374e9a12    default   (1 inbound, 1 outbound)
NACL    acl-0e112d0a8a1c5a0fc   default
```

### Default security group

```
Inbound :  protocol -1 (ALL),  source = ITSELF (sg-007e5b550374e9a12)
Outbound:  protocol -1 (ALL),  destination = 0.0.0.0/0
```

The inbound source is **the group itself**, not `0.0.0.0/0`. So the default SG is **closed to the internet** — that's why a fresh EC2 is unreachable until you add a rule.

### Default NACL

```
Inbound :  100 allow all 0.0.0.0/0 ; 32767 deny all
Outbound:  100 allow all 0.0.0.0/0 ; 32767 deny all
```

Rule 100 allows everything, so 32767 is never reached. **Default NACL is wide open** — the opposite of the default SG.

### The five differences

| | **Security Group** | **NACL** |
|---|---|---|
| Level | Instance / ENI | **Subnet** |
| Stateful? | ✅ **stateful** | ❌ **stateless** |
| Rules can | **Allow only** | Allow **and Deny** |
| Evaluation | All rules OR-ed (union) | **Numbered, first match wins** |
| Default | Deny in, allow out | Allow all |

### Stateful vs stateless — the interview question

**SG is stateful:** allow inbound 443, the reply goes out automatically.

**NACL is stateless:** every packet judged independently. Allow inbound 443, and the **reply gets blocked** — it's a new outbound packet from a random ephemeral port (1024–65535).

```
Client:54321 ──▶ Server:443     ✅
Server:443   ──▶ Client:54321   ❌ blocked unless outbound ephemeral allowed
```

**That's why NACLs need ephemeral port ranges.** "I opened 443 on my NACL, why doesn't HTTPS work?" — this is the answer.

### Scenario answers (my own reasoning)

**Q: Default SG + add inbound tcp/22 from 0.0.0.0/0, default NACL unchanged. Can I SSH?**
✅ **Yes.** SG rules are a **union** — any single matching Allow permits traffic. The new rule doesn't override the self-referential one; it adds.

**A: Remove the SG rule — can I SSH?**
✅ **No.** Default SG inbound only matches itself. Nothing external → implicit deny.

**B: NACL changed to `100 deny 0.0.0.0/0`, `200 allow 0.0.0.0/0` — can I SSH?**
✅ **No.** NACL evaluation stops at the **first match**. Rule 100 denies; rule 200 is dead code.

**C: Private subnet (no IGW), SG allows 22, NACL allows all — can I SSH?**
✅ **No.** The packet never arrives. Neither SG nor NACL is consulted.

### Debug order

```
Route table → IGW → NACL → SG → app
```

A block at **any** layer looks identical from outside: "can't connect." Check widest scope first.

---

## Part D — CloudWatch Logs

### The permission gap I hit

```bash
aws logs describe-log-groups --profile portfolio --region ap-south-1
```
```
AccessDeniedException: ... logs:DescribeLogGroups ...
because no identity-based policy allows the logs:DescribeLogGroups action
```

My policies were EC2, IAM and S3 read-only — **no CloudWatch Logs at all.**

**Couldn't fix it from the CLI:** attaching a policy needs `iam:AttachUserPolicy` (a write action), and I have `IAMReadOnlyAccess`. Another implicit deny.

**Fixed in the console as root** — IAM → Users → Athena → Add permissions → attach `CloudWatchLogsReadOnlyAccess`. This is a legitimate, textbook use of root: account-level permission changes.

**After:** `{"logGroups": []}` — empty list, **no error.** Empty means the permission resolves; the account simply has no logs.

### The model

```
Log GROUP      /ecs/my-app             ← retention lives here
  └ Log STREAM  ecs/my-app/abc123      ← one per task/container
      └ EVENT   "2026-10-31 ERROR ..." ← timestamped line
```

| Concept | Note |
|---|---|
| Log group | container; **set retention** or cost grows forever |
| Log stream | one source |
| Event | one line |
| Metric filter | pattern → metric |
| Insights | SQL-like queries |

### Two things that bite people

1. **No retention = logs kept forever = ongoing bill.** Always set retention.
2. **`filter-log-events` costs per GB scanned.** Insights is faster for broad queries but has its own cost.

### Commands for Phase 2

```bash
aws logs describe-log-groups
aws logs describe-log-streams --log-group-name /ecs/my-app
aws logs tail /ecs/my-app --follow                 # the workhorse
aws logs filter-log-events --log-group-name /ecs/my-app --filter-pattern "ERROR"
```

### Current account state

```json
{"logGroups": [], "MetricAlarms": [], "CompositeAlarms": [], "LogAlarms": []}
```

### Metric filter patterns (close to grep)

| CloudWatch | grep equivalent |
|---|---|
| `"ERROR"` | `grep ERROR` |
| `"ERROR" -"DEBUG"` | `grep ERROR \| grep -v DEBUG` |
| `[level = ERROR, ...]` | structured parse |
| `{ $.level = "ERROR" }` | JSON logs |

**This is `log-summary.sh` running in AWS instead of my terminal.**

### Alarm anatomy (fields I'll use in Phase 2)

| Field | Meaning |
|---|---|
| `MetricName` / `Namespace` | what to watch (`CPUUtilization` / `AWS/ECS`) |
| `Statistic` | Average, Sum, Maximum |
| `Period` | seconds per data point |
| `EvaluationPeriods` | how many periods to check |
| `Threshold` | the comparison value |
| `ComparisonOperator` | `GreaterThanThreshold` etc. |
| `AlarmActions` | SNS topic ARNs |

### Design exercise — alarms for my future ECS deployment

**Deferred to Phase 2** (when ECS actually exists and there are real baselines to threshold against). CloudWatch namespaces are empty right now because metrics are published by running resources, not predefined:

```
AWS/ECS              0 metrics
AWS/ApplicationELB   0 metrics
AWS/EC2              0 metrics
```

**The spec to fill in during Phase 2:**

| Signal | Metric | Threshold | Why it matters | Action |
|---|---|---|---|---|
| Errors | `HTTPCode_Target_5XX_Count` (Sum) | > 5 in 5 min | app returning server errors — users see failures | `aws logs tail /ecs/my-app --follow`; recent deploy → roll back |
| LB failures | `HTTPCode_ELB_5XX_Count` (Sum) | | load balancer itself failed | |
| No healthy targets | `UnHealthyHostCount` (Max) | | every task failing health checks — site down | |
| Slow | `TargetResponseTime` (p99) | | p99 shows the slow tail users feel; Average hides it | |

### Framework: four golden signals

| Signal | Question | ECS/ALB metric |
|---|---|---|
| Latency | how slow? | `TargetResponseTime` |
| Traffic | how much? | `RequestCount` |
| Errors | how many failing? | `HTTPCode_Target_5XX_Count` |
| Saturation | how full? | `CPUUtilization`, `MemoryUtilization` |

**Start from "what does broken look like to a user?" — not from a metric list.**

### Where ECS metrics come from

| Namespace | Contains | Dimensions |
|---|---|---|
| `AWS/ECS` | `CPUUtilization`, `MemoryUtilization` | `ClusterName`, `ServiceName` |
| `AWS/ApplicationELB` | `TargetResponseTime`, `HTTPCode_Target_5XX_Count`, `UnHealthyHostCount`, `RequestCount` | `LoadBalancer`, `TargetGroup` |
| `AWS/EC2` | host `CPUUtilization` (N/A on Fargate) | `InstanceId` |

**The ALB is the best alarm source** — ECS service metrics show resource usage, the ALB shows whether *users* are succeeding.

### Three tiers

| Tier | What | Use for |
|---|---|---|
| 1. **Symptom** | users hurting now | **paging** |
| 2. **Cause** | trending wrong | dashboards |
| 3. **Capacity** | nearing a limit | weekly review |

**Alarm on tier 1. Dashboard tier 2. Review tier 3.**

### Why not alarm on CPU

A service at 90% CPU serving fine isn't broken. Paging at 3am for it teaches people to ignore alarms. **Alarm on user impact.**

### Threshold discipline

1. Run the app first, gather a baseline
2. Set threshold **above normal peaks, below "users are complaining"**
3. Use `EvaluationPeriods` ≥ 2 so a single blip doesn't fire
4. Every alarm needs an SNS topic with a **confirmed** subscription

```bash
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime --dimensions Name=LoadBalancer,Value=app/xxx \
  --start-time 2026-11-01T00:00:00Z --end-time 2026-11-02T00:00:00Z \
  --period 300 --statistics Average Maximum --profile portfolio
```

### Common traps

| Trap | Why it's wrong |
|---|---|
| Alarm on CPU alone | busy ≠ broken |
| `> 0` on 5xx | one error pages you at 3am |
| `EvaluationPeriods: 1` | single blip fires |
| Alarm with no SNS action | nobody is told |
| Alarming on everything | alarm fatigue → muted |

**Minimum viable alarm:** metric + threshold + ≥2 evaluation periods + SNS with confirmed subscription.

---

## Part E — Two errors, two lessons

### Error 1 — `IllegalLocationConstraintException`

```cmd
aws s3api create-bucket --bucket test-denied-bucket-977099009814 --region ap-south-1 --profile portfolio
```
```
An error occurred (IllegalLocationConstraintException) when calling the
CreateBucket operation: The unspecified location constraint is incompatible
for the region specific endpoint this request was sent to.
```

**Cause:** S3's default region is `us-east-1`. Every other region requires an explicit `LocationConstraint`.

**Fix:**
```cmd
--create-bucket-configuration LocationConstraint=ap-south-1
```

**Lesson:** request validation happens **before** authorization.

```
1. Parse request        → syntax
2. Validate parameters  → your failure point
3. Authenticate         → who
4. Authorize            → AccessDenied lives here
```

**Rule:** if you expect `AccessDenied` and get something else, **the request is malformed** — permission was never checked.

### Error 2 — the real `AccessDenied`

```cmd
aws s3api create-bucket --bucket test-denied-bucket-977099009814 --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1 --profile portfolio
```
```
An error occurred (AccessDenied) when calling the CreateBucket operation:
User: arn:aws:iam::977099009814:user/Athena is not authorized to perform:
s3:CreateBucket on resource: "arn:aws:s3:::test-denied-bucket-977099009814"
because no identity-based policy allows the s3:CreateBucket action
```

### Decoding the message

| Part | Tells you |
|---|---|
| `AccessDenied` | IAM refused — not network, not syntax |
| `CreateBucket` | which API call |
| `arn:aws:iam::...:user/Athena` | **who** made the call |
| `s3:CreateBucket` | permission needed |
| `arn:aws:s3:::bucket-name` | target *(S3 ARNs have no region/account)* |
| **`because no identity-based policy allows`** | 🔑 **where the fix belongs** |

### The "because" clause is the diagnostic gold

| "Because..." | Block location | Fix |
|---|---|---|
| **`no identity-based policy allows`** | user/role | attach a policy |
| `explicit deny in a permissions boundary` | boundary | loosen boundary |
| `explicit deny in a service control policy` | Organizations SCP | change OU policy |
| `explicit deny in a resource-based policy` | bucket/KMS key policy | edit resource policy |
| `no resource-based policy allows` | missing bucket policy | add bucket policy |

**Mine** was the cleanest form: no SCP, no boundary, no bucket policy — just a missing Allow.

### Why it proves the policy works

```
Permissions : s3:Get*, s3:List*
Attempt     : s3:CreateBucket
            ↑ "Create" isn't "Get"/"List" → no match → implicit deny
```

**Implicit deny** = not allowed by anything = denied. You never write a `Deny` to block something — you simply don't allow it.

---

## What I learned (in my own words)

*(fill in — 3-5 sentences: why "because no identity-based policy allows" is the most useful part of an AccessDenied? what's the practical difference between stateful and stateless for debugging? why does a private subnet make SG and NACL irrelevant?)*
