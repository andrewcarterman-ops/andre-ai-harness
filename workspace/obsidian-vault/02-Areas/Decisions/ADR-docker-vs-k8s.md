---
date: 2026-04-08
time: 01:39
type: adr
title: Docker-vs-K8s-Entscheidung
category: project
tags:
  - docker
  - ecc
  - kubernetes
  - project
  - adr
related_notes:
  - 📁 [[ADR-test-k8s-migration]] (8 gemeinsame Begriffe: wir, haben, docker)
  - 📦 [[SNIPPET-Template]] (3 gemeinsame Begriffe: ecc, framework, use)
  - 📝 [[patterns]] (5 gemeinsame Begriffe: entschieden, für, ecc)
related_count: 5
adr_id: ADR-20260408-001
status: Proposed
priority: Medium
---

# Docker-vs-K8s-Entscheidung

Wir haben entschieden, Docker Compose für das ECC Framework zu nutzen. Kubernetes ist zu komplex für unseren Use Case.