# AI-First AWS DevOps — Portfolio

Hands-on work rebuilding production-grade AWS DevOps skills after a career break — building toward **Terraform + Docker + ECS + CI/CD**, with evidence for every claim in this repo.

> **Honest framing:** this is independent portfolio work, not professional experience. Each entry below is a lab I actually ran, with the real command output committed alongside it.

---

## What's in here

### `scripts/aws-cli/` — working operations tools

Three read-only tools, all with error handling and meaningful exit codes.

**`health-check.sh`** — confirms identity and region, then inventories the account.

```bash
./scripts/aws-cli/health-check.sh --profile portfolio --region ap-south-1
```

```
=== IDENTITY ===
  [ OK ] arn     : arn:aws:iam::<account>:user/Athena
  [ OK ] account : <account>
  [ OK ] region  : ap-south-1

=== NETWORKING (VPCs) ===
  [ OK ] vpc vpc-xxxxxxxx  cidr=172.31.0.0/16  default=True

=== STORAGE (S3) ===
  [ OK ] no buckets (0)
```

Exit codes: `0` all clear · `1` warnings · `2` bad config · `3` auth failure.

**`log-summary.sh`** — counts a log file's lines by severity.

```bash
./scripts/aws-cli/log-summary.sh /var/log/app.log
```

```
=== LOG SUMMARY: /var/log/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
```

Exit codes: `0` clean · `1` log contains errors · `2` bad input.

**`log_summary.py`** — the same tool, rewritten in Python (same output, same exit codes).

```bash
python scripts/aws-cli/log_summary.py testdata/app.log
```

```
=== LOG SUMMARY: testdata/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
```

Two implementations of one design — used to prove the concepts transfer across languages.

All scripts are read-only by design and were tested against their failure paths, not just the happy path.

### `lab-log/` — the evidence

One file per session: the commands actually run and the output actually returned. No paraphrasing — real terminal output.

| Entry | Topic |
|---|---|
| `day1.md` | Linux fundamentals — permissions, processes, disk/memory, logs |
| `day2.md` | Networking — interfaces, DNS, connectivity, ports, client/server |
| `day2-git.md` | Git — commit, branch, merge, rollback, push |
| `day3.md` | AWS CLI — identity, `--query`, inventory, IAM troubleshooting |
| `day4.md` | Bash scripting — first script written from scratch |
| `day6.md` | Python — porting the script; YAML and its silent-parse dangers |
| `day7.md` | Linux administration — SSH key auth, users, sudo, PATH, services |
| `day8.md` | AWS depth — IAM policies, security groups vs NACLs, CloudWatch, AccessDenied |
| `day9.md` | CP Domain 1 + 4 — cloud concepts, pricing models, Free Tier, Organizations, support plans |
| `day10.md` | CP Domain 2 — shared responsibility, IAM hygiene, encryption/KMS, detection, secrets, compliance |

---

## Skills demonstrated so far

| Area | Evidence |
|---|---|
| **Linux** | File permissions (`chmod`), process control (`ps`/`kill`), disk & memory analysis, log filtering |
| **Networking** | Interface/IP inspection, connectivity vs DNS isolation, port inspection, client-server model |
| **Git** | Three-stage workflow, branching and merging, rollback, `.gitignore` hygiene |
| **AWS CLI** | Named profiles, identity verification, JMESPath `--query`, read-only inventory |
| **IAM** | Diagnosed and fixed a real `AccessDenied` — least privilege, narrow policies over broad ones |
| **Bash** | Validation, exit codes, error handling, functions, loops, fail-fast design |
| **Python** | `sys.argv`/`sys.exit`, `with open()`, f-strings, `Counter`, guard clauses; YAML parsing |
| **Linux administration** | SSH key auth (`sshd`, StrictModes, `authorized_keys`), user/group management, `sudo`, PATH, systemd vs containers |
| **AWS networking security** | Security groups (stateful, allow-only, union) vs NACLs (stateless, ordered, allow+deny); debug order routes → NACL → SG |
| **CloudWatch** | Log groups/streams/events, retention as cost control, metric filter patterns, alarm anatomy |
| **Cloud concepts** | Six advantages, CapEx vs OpEx, IaaS/PaaS/SaaS responsibility split, 6 Well-Architected pillars, 6 CAF perspectives, regions vs AZs vs edge locations |
| **AWS cost & governance** | Pricing models (On-Demand/RI/Savings Plans/Spot), Free Tier arithmetic, TCO, Organizations + SCP ceiling, Budgets vs Cost Explorer vs CUR, support plan tiers |
| **AWS security practice** | Shared responsibility by service type, root/MFA/password-policy hygiene, SSE-S3 vs KMS vs SSE-C, envelope encryption, CloudTrail vs Config vs GuardDuty vs Inspector vs Macie, Shield vs WAF, Secrets Manager vs Parameter Store |
| **Safety practice** | Read-only tooling, identity confirmed before every operation, no secrets committed |

---

## Approach

Deliberate choices, because these are the habits that matter in operations:

- **Read-only by default.** The AWS tools only call `describe`/`list`/`get`. Nothing here mutates an account.
- **Identity before action.** Every script proves which account it's talking to before touching anything. Working in the wrong account is how people destroy things.
- **Exit codes are the product.** Pretty output is for humans; the exit code is what automation reads. Distinct codes for distinct failure types.
- **Evidence over assertion.** Every lab-log entry contains real output. If it's claimed here, it ran.
- **Failure paths tested too.** A script that only works when everything's fine isn't finished.

---

## Roadmap

Currently in the foundations phase. Next milestones, in order:

- [x] Linux fundamentals + administration (SSH, users, services), networking, Git
- [x] AWS CLI read-only operations + first scripts
- [x] Python tooling + YAML
- [ ] Terraform + Docker
- [ ] ECS Fargate deployment
- [ ] GitHub Actions CI/CD with OIDC
- [ ] Observability + runbooks
- [ ] AI-assisted incident triage with evaluation

---

## Repo conventions

- `lab-log/` — public. Session evidence, real output.
- `scripts/` — public. Working tools.
- `docs/` — private (gitignored). Personal study notes; not published.

No credentials, keys, tokens, or account-sensitive data are committed. AWS access uses a named CLI profile with read-only IAM permissions.