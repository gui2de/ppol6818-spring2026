# HFC Assignment — Tanzania eLMS RCT
**PPOL 6818 | Anurita Srivastava, Aqsa Zaidi, Harold Shi, Naomi Yang**

---

## What this is

Three high frequency checks (HFCs) for our Tanzania eLMS RCT. Each check targets a specific data quality problem that could corrupt the study's results if left undetected. The checks are written in Stata and compiled into a Quarto HTML document (`hfc_main.qmd`).

---

## Check 1 — Teacher Registration Integrity

We're worried that the same teacher might be registered multiple times on the eLMS under different accounts — different spellings of their name, a new registration after transferring schools, etc. This inflates the denominator of our main outcome (the share of registered teachers who complete a module), so the completion rate looks artificially low. It also corrupts our composite resource index, which we use to classify wards as high- or low-resource for the equity analysis.

The check flags three problems at the school level: duplicate phone numbers within a school (same person, two accounts), a teacher ID appearing in more than one school at the same time (impossible — means a data merge went wrong), and cases where the number of teachers in Matomo differs from TIE's administrative records by more than 20%. We use simulated data for this check since we don't yet have the real roster.

---

## Check 2 — Gaming Detection

In treated wards, headteachers receive a monthly ranking of their ward's schools by eLMS completion. The concern is that some headteachers — especially in T2, where there's a structured accountability prompt — might pressure a handful of teachers to quickly complete modules right after the report lands, just to improve their school's rank. This would inflate completion numbers without reflecting genuine engagement.

To detect this, we look at each school's completion activity in the week immediately after each monthly report is delivered. We compare that week's completions to the school's typical baseline (calculated from non-report weeks) using a z-score, and we also check whether the completions are suspiciously concentrated among just one or two teachers (measured by the HHI). Schools that show both a large spike and high concentration in two or more report months get flagged for follow-up in the endline survey's coercion module. We use simulated data for this check.

---

## Check 3 — Matomo Data Cleaning & Usage Descriptives

Our primary outcome comes entirely from Matomo, the web analytics platform tracking activity on the eLMS. Matomo exports are messy: each CSV has hundreds of columns (one block per page action in a session), the column count varies across monthly exports making a simple append fail, and about 60% of sessions have no user ID because the teacher wasn't logged in. Shared devices in schools make this worse — a single browser cookie might represent multiple teachers.

This check automates the full cleaning pipeline. It imports however many monthly CSV exports are available, renames the unlabelled columns using their variable labels, drops irrelevant columns, appends everything together, and then identifies meaningful events (quiz attempts, quiz completions, course page visits) by matching URL patterns. It saves a clean session-level dataset and a user-level dataset, and produces eight figures covering which pages are most visited, where users are coming from, what devices they use, when during the day they log in, and how engagement has trended month by month. Unlike the other two checks, this one runs on the real Matomo exports. It runs only on Stata SE.
