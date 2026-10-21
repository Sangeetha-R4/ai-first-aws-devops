# Day 2 — Git (Repo is born)

**Date:** 2026-10-21
**Goal:** Turn the project folder into a version-controlled portfolio on GitHub.

---

## 1. Setup

```
$ git --version
git version 2.41.0.windows.3

$ git config --global user.name "Sangeetha-R4"
$ git config --global user.email "reachrsangeetha@gmail.com"

$ winget install GitHub.cli        # → gh 2.103.0
$ gh auth login                     # → ✓ Logged in as Sangeetha-R4
```

---

## 2. First commit (the 3-stage model)

```
$ git init
Initialized empty Git repository in C:/Users/Imvin/ai-first-aws-devops/.git/

$ git status                          # untracked: docs/, lab-log/
$ git add .                           # stage everything
$ git status                          # "Changes to be committed" (new files)
$ git commit -m "Day 1-2: Linux fundamentals and networking evidence"
 5 files changed, 698 insertions(+)

$ git log --oneline
1a219bb (HEAD -> master) Day 1-2: Linux fundamentals and networking evidence
```

**The 3 stages:** working dir → `git add` (staging) → `git commit` (saved snapshot).

---

## 3. Push to GitHub

```
$ gh repo create ai-first-aws-devops --public --source . --push
Created repository Sangeetha-R4/ai-first-aws-devops on github.com
✓ Pushed commits to https://github.com/Sangeetha-R4/ai-first-aws-devops.git
```

Repo is live: **https://github.com/Sangeetha-R4/ai-first-aws-devops**

---

## 4. Branching + merging

```
$ git checkout -b add-readme          # create + switch to new branch
$ git status                          # "On branch add-readme"

# (created README.md, then:)
$ git add README.md
$ git commit -m "Add README with project overview"
[add-readme e2e7cf7] ... 1 file changed, 9 insertions(+)

$ git log --oneline
e2e7cf7 (HEAD -> add-readme) Add README with project overview
1a219bb (origin/master, master) Day 1-2: Linux fundamentals and networking evidence

$ git checkout master
$ git merge add-readme
Updating 1a219bb..e2e7cf7
Fast-forward
```

**Key insight:** `HEAD -> add-readme` vs `master` — branches diverge, then merge back. "Fast-forward" = straight line, no conflict.

---

## 5. Rollback (git restore)

```
$ echo BAD CHANGE >> README.md        # simulate a mistake
$ git status                          # "modified: README.md" (not staged)
$ git restore README.md               # discard the edit, back to last commit
$ type README.md                      # BAD CHANGE is gone
```

**File states learned:** `untracked` (new) · `staged` (added) · `modified` (edited since commit).

---

## 6. Push the merged work

```
$ git push
1a219bb..e2e7cf7  master -> master
```

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: what are the 3 stages of a commit? what's a branch and why use one? what did git restore do?)*
