# Hook: Post-Execution Review
# Trigger: Nach Ausführung von Plans oder kritischen Operationen
# Hook-ID: review:post_execution
# Priorität: 150 (nach session:end, vor cleanup)

## Beschreibung
Dieser Hook führt automatisierte Reviews durch nach:
- Plan-Ausführung
- Kritischen Tool-Operationen (file, exec)
- Fehlern/Exceptions

## Trigger-Bedingungen

```yaml
hook:
  id: "review:post_execution"
  triggers:
    - event: "plan:completed"
      condition: "review_required == true"
      
    - event: "plan:failed"
      condition: "always"
      severity: "high"
      
    - event: "tool:executed"
      tool: ["write", "edit", "exec"]
      condition: "review_config.execution_review.enabled"
      
    - event: "error:critical"
      condition: "always"
      immediate: true
```

## Review-Prozess

### 1. Prüfung auslösen
```
IF plan.status == "failed" THEN
  review_triggered = true
  review_type = "error_review"
ELSE IF plan.review_required == true THEN
  review_triggered = true
  review_type = "plan_review"
ELSE IF tool.category in ["destructive", "critical"] THEN
  review_triggered = true
  review_type = "execution_review"
```

### 2. Review durchführen
```
1. Lade review-config.yaml
2. Identifiziere Review-Typ
3. Führe Checkliste durch
4. Bewerte Severity (low/medium/high)
5. Generiere Vorschläge
6. Speichere Review-Ergebnis
```

### 3. Integration mit self-improving-andrew
```
IF review.findings.include?("pattern") THEN
  write_to: "memory/self-improving/review-patterns.md"
  format: "Pattern: {description}\nCorrection: {solution}\n"
END

IF review.feedback.present? THEN
  write_to: "memory/self-improving/review-feedback.md"
  format: "[{timestamp}] {context}: {feedback}\n"
END
```

## Review-Output-Format

```markdown
# Review: {plan_id}
**Datum:** {timestamp}
**Typ:** {review_type}
**Auslöser:** {trigger}

## Zusammenfassung
- Status: {passed | failed | partial}
- Erfolgsrate: {X}/{Y} Schritte ({Z}%)
- Severity: {low | medium | high}

## Checkliste
- [x] Alle Schritte ausgeführt?
- [ ] Erfolgskriterien erfüllt?
- [x] Keine Seiteneffekte?
...

## Gefundene Probleme
| # | Problem | Schwere | Lösung |
|---|---------|---------|--------|
| 1 | {Beschreibung} | medium | {Fix} |

## Vorschläge
1. {Verbesserungsvorschlag}
2. {Verbesserungsvorschlag}

## Feedback für self-improving-andrew
```
{Extrahierte Patterns}
```

## Aktionen
- [ ] Manuelles Review erforderlich
- [ ] Rollback empfohlen
- [x] Auto-korrektur möglich
```

## Integration mit Plans

### In Plan-Template verfügbar
```yaml
review:
  status: "completed"
  result: "passed"
  severity: "low"
  findings: 0
  reviewed_by: "auto"
  reviewed_at: "2026-03-25T22:40:00+01:00"
```

### Manuelle Review-Anforderung
```bash
# Trigger manuelles Review
openclaw review:trigger plan-id

# Review-Status prüfen
openclaw review:status plan-id
```

## Konfiguration

Review-Regeln werden definiert in:
- `registry/review-config.yaml`

## Fehlerbehandlung

### Wenn Review selbst fehlschlägt
```
Log: "Review failed: {error}"
Notify: user (if critical)
Continue: true (nicht blockierend)
```

### Wenn self-improving Skill nicht verfügbar
```
Log: "Skill 'self-improving-andrew' not available"
Save to: "memory/reviews/orphaned-feedback-{timestamp}.md"
Retry: false
```

## Status

- [x] Hook-Definition erstellt
- [x] Review-Config erstellt
- [ ] Automatische Trigger-Integration (Phase 2+)
- [ ] Implementierung Review-Logik (Phase 2+)

---

**Hinweis:** Dies ist ein Template. Die tatsächliche Ausführung erfolgt über
die Hook-Engine wenn die Trigger-Integration implementiert wird.
