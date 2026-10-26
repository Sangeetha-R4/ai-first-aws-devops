# Day 3 — AWS CLI as an Operations Tool

**Date:** 2026-10-23 (continued 2026-10-26)
**Goal:** Inspect the AWS account read-only, read the output, and build a reusable health-check script.

---

## 1. The identity ritual (run first, every session)

```
$ aws sts get-caller-identity --profile portfolio
{
    "UserId": "AIDA6G75DV4LHZZMZPPOO",
    "Account": "977099009814",
    "Arn": "arn:aws:iam::977099009814:user/Athena"
}
```

ARN format: `arn:aws:iam::<account-id>:user/<username>`

---

## 2. Command anatomy + output formats

```
aws <service> <action> --profile <name> --region <region> [--query ...] [--output ...]
```

| Format | Use |
|---|---|
| `json` | scripts / automation (default) |
| `table` | humans reading on screen |
| `text` | extracting single values |

### Gotcha fixed: `'more' is not recognized`

`--output table` pipes through a pager; `more` isn't on PATH in this Git-Bash environment.

```
$ aws configure set cli_pager ""
```

→ table output now prints directly. **Lesson:** if a command "fails" but you think the call worked, retest with `--output json` — if that works, it's a presentation problem, not an execution problem.

---

## 3. `--query` (JMESPath)

```
$ aws sts get-caller-identity --profile portfolio --query Account --output text
977099009814
```

### Three patterns

| Pattern | Result |
|---|---|
| `Vpcs[].VpcId` | one field per line |
| `Vpcs[].CidrBlock` | one field per line |
| `Vpcs[].[VpcId,CidrBlock]` | multiple fields, tab-separated (script workhorse) |

```
$ aws ec2 describe-vpcs --profile portfolio --query "Vpcs[].VpcId" --output text
vpc-0409bd0af26230be4

$ aws ec2 describe-vpcs --profile portfolio --query "Vpcs[].CidrBlock" --output text
172.31.0.0/16

$ aws ec2 describe-vpcs --profile portfolio --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-0409bd0af26230be4   172.31.0.0/16
```

---

## 4. Inventory of the account

```
$ aws s3 ls --profile portfolio
(silence — 0 buckets)

$ aws iam list-users --profile portfolio --query "Users[].UserName" --output text
Athena

$ aws ec2 describe-instances --profile portfolio \
    --query "Reservations[].Instances[].[InstanceId,State.Name]" --output text
(silence — 0 instances)
```

**Key lesson: empty output is a valid answer, not an error.**
- Empty = "none exist" → exit code 0, command succeeded
- `aws: [ERROR]` prefix = actual failure (e.g. AccessDenied)

A script that treats empty as failure will break constantly.

### The VPC found (default VPC)

| Field | Value |
|---|---|
| VpcId | `vpc-0409bd0af26230be4` |
| CidrBlock | `172.31.0.0/16` (65,536 addresses) |
| IsDefault | `true` |
| State | `available` |

`172.31.0.0/16` is a **private** range — same concept as the container's `172.17.0.2`: reachable outward via NAT, not directly from the internet.

---

## 5. IAM problem hit and fixed

Full write-up in `docs/troubleshooting-notebook.md` (Entry 1). Summary:

- `ec2:DescribeVpcs` → **UnauthorizedOperation**
- Investigation showed `Athena` had **no policies attached**
- Attaching `ReadOnlyAccess` failed: *"The selected policies exceed this account's quota"* (that policy is documented as exceeding the managed-policy size limit; also a brand-new-account console quirk)
- **Fix:** attached three narrow policies instead
  - `AmazonEC2ReadOnlyAccess`
  - `AmazonS3ReadOnlyAccess`
  - `IAMReadOnlyAccess`
- Verified working afterwards.

**Lesson:** narrow policies > one giant policy. That *is* least privilege, met in the wild.

---

## 6. Health-check script (the deliverable)

`scripts/aws-cli/health-check.sh` — read-only account health check.

### Output

```
=== PRECONFIGURED SETTINGS ===
  profile : portfolio
  region  : ap-south-1

=== IDENTITY ===
  [ OK ] arn     : arn:aws:iam::977099009814:user/Athena
  [ OK ] account : 977099009814
  [ OK ] region  : ap-south-1

=== NETWORKING (VPCs) ===
  [ OK ] vpc vpc-0409bd0af26230be4  cidr=172.31.0.0/16  default=True

=== STORAGE (S3) ===
  [ OK ] no buckets (0)

=== COMPUTE (EC2 instances) ===
  [ OK ] no running instances (0)

=== IAM (users) ===
  [ OK ] user: Athena

=== SUMMARY ===
  All checks passed. No warnings.
```

### Design decisions

| Decision | Why |
|---|---|
| Identity check **first** | Never touch resources without proving which account you're in |
| Read-only (`describe`/`list` only) | Safe to run anywhere, anytime |
| `set -uo pipefail` | Catch undefined variables and mid-pipeline failures |
| Distinct exit codes | Automation can tell failure types apart |
| `${VAR:-default}` | Override via env without editing the script |
| Empty vs `aws: [ERROR]` handled separately | "None exist" ≠ "couldn't check" |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | all checks passed |
| 1 | completed with warnings |
| 2 | bad input / profile not configured |
| 3 | authentication or permission failure |

### Failure paths tested (not just the happy path)

```
$ bash scripts/aws-cli/health-check.sh --profile doesnotexist
  [FAIL] profile 'doesnotexist' is not configured on this machine.
EXIT: 2

$ bash scripts/aws-cli/health-check.sh --profile default
  [FAIL] could not authenticate with profile 'default'
  aws: [ERROR] InvalidClientTokenId ...
EXIT: 3
```

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: what does `--query` save you? why check identity first? why do exit codes matter more than pretty output?)*
