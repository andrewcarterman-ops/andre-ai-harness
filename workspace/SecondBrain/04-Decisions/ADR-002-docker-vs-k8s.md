---
date: 08-04-2026
type: decision
status: proposed
tags: [decision, adr, docker, kubernetes, ecc]
adr_id: ADR-20260408-001
priority: medium
---

# ADR-002: Docker vs Kubernetes für ECC Framework

## Kontext

Infrastruktur-Entscheidung für das ECC Framework: Container-Orchestrierung.

## Entscheidung

**Docker Compose** wird für das ECC Framework genutzt.

**Begründung:** Kubernetes ist zu komplex für den aktuellen Use Case.

## Konsequenzen

- ✅ Einfacheres Setup
- ✅ Geringere Lernkurve
- ✅ Schnellere Iteration
- ⚠️ Später möglicherweise Migration zu K8s nötig bei Skalierung

## Alternativen betrachtet

- Kubernetes: Zu komplex für aktuellen Scope
- Raw Docker: Zu manuell

## Verwandte Entscheidungen
- [[ADR-003-test-k8s-migration|ADR-003: K8s Migration]]

## Erstellt
08-04-2026
