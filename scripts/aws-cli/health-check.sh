#!/usr/bin/env bash
#
# health-check.sh — read-only AWS account health/inventory check
#
# Purpose: confirm identity and region FIRST, then report the state of
#          selected resources. Safe by design: every call is a describe/list/get.
#
# Usage:
#   ./health-check.sh [--profile portfolio] [--region ap-south-1]
#
# Exit codes:
#   0  all checks ran, no problems
#   1  checks ran but something needs attention (e.g. no VPC, resources untagged)
#   2  bad input / missing prerequisites (profile not configured)
#   3  authentication or permissions failure
#
set -uo pipefail

# ---------- configuration ----------
PROFILE="${AWS_PROFILE:-portfolio}"
REGION="${AWS_REGION:-ap-south-1}"

# allow --profile / --region overrides
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region)  REGION="$2";  shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

WARNINGS=0

# ---------- helpers ----------
info() { printf '%s\n' "$*"; }
ok()   { printf '  [ OK ] %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
hdr()  { printf '\n=== %s ===\n' "$*"; }

# aws wrapper: always passes profile + region, returns output as text
awsq() { aws "$@" --profile "$PROFILE" --region "$REGION" --output text 2>&1; }

# ---------- 1. prerequisites ----------
hdr "PRECONFIGURED SETTINGS"
info "  profile : $PROFILE"
info "  region  : $REGION"

if ! aws configure list-profiles 2>/dev/null | grep -qx "$PROFILE"; then
  info "  [FAIL] profile '$PROFILE' is not configured on this machine."
  info "         run: aws configure --profile $PROFILE"
  exit 2
fi

# ---------- 2. identity (ALWAYS first) ----------
hdr "IDENTITY"
IDENTITY="$(aws sts get-caller-identity --profile "$PROFILE" --output json 2>&1)"
if [ $? -ne 0 ]; then
  info "  [FAIL] could not authenticate with profile '$PROFILE'"
  printf '         %s\n' "$IDENTITY"
  exit 3
fi

ARN="$(printf '%s' "$IDENTITY" | sed -n 's/.*"Arn": *"\([^"]*\)".*/\1/p')"
ACCOUNT="$(printf '%s' "$IDENTITY" | sed -n 's/.*"Account": *"\([^"]*\)".*/\1/p')"
ok "arn     : $ARN"
ok "account : $ACCOUNT"
ok "region  : $REGION"

# ---------- 3. inventory ----------
hdr "NETWORKING (VPCs)"
VPC_OUT="$(awsq ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,IsDefault]')"
if [ -z "$VPC_OUT" ] || printf '%s' "$VPC_OUT" | grep -q '^aws:'; then
  warn "no VPCs found, or access denied:"
  printf '         %s\n' "$VPC_OUT"
else
  printf '%s\n' "$VPC_OUT" | while IFS=$'\t' read -r id cidr isdefault; do
    ok "vpc $id  cidr=$cidr  default=$isdefault"
  done
fi

hdr "STORAGE (S3)"
if BUCKETS="$(awsq s3 ls)"; then
  if [ -z "$BUCKETS" ]; then
    ok "no buckets (0)"
  else
    printf '%s\n' "$BUCKETS" | while read -r line; do
      [ -n "$line" ] && ok "bucket: $line"
    done
  fi
else
  warn "could not list buckets: $BUCKETS"
fi

hdr "COMPUTE (EC2 instances)"
INSTANCES="$(awsq ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType]')"
if [ -z "$INSTANCES" ] || printf '%s' "$INSTANCES" | grep -q '^aws:'; then
  ok "no running instances (0)"
else
  printf '%s\n' "$INSTANCES" | while IFS=$'\t' read -r id state type; do
    ok "instance $id  state=$state  type=$type"
  done
fi

hdr "IAM (users)"
USERS="$(awsq iam list-users --query 'Users[].UserName')"
if [ -z "$USERS" ] || printf '%s' "$USERS" | grep -q '^aws:'; then
  warn "could not list IAM users: $USERS"
else
  printf '%s\n' "$USERS" | while read -r u; do
    [ -n "$u" ] && ok "user: $u"
  done
fi

# ---------- 4. summary ----------
hdr "SUMMARY"
if [ "$WARNINGS" -eq 0 ]; then
  info "  All checks passed. No warnings."
  exit 0
else
  info "  Completed with $WARNINGS warning(s). Review above."
  exit 1
fi
