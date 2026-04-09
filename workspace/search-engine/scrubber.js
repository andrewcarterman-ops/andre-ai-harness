/**
 * PII Scrubber - Sensitive Data Detection & Masking
 * 
 * Erkennt und maskiert:
 * - API Keys (OpenAI, Anthropic, etc.)
 * - Access Tokens
 * - Private Keys
 * - Passwörter
 * - E-Mail-Adressen (optional)
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');

// Muster für sensitive Daten
const SENSITIVE_PATTERNS = {
  // API Keys
  openai_key: {
    pattern: /sk-[a-zA-Z0-9]{48}/g,
    mask: 'sk-***REDACTED***',
    severity: 'critical',
    description: 'OpenAI API Key'
  },
  anthropic_key: {
    pattern: /sk-ant-[a-zA-Z0-9]{32,}/g,
    mask: 'sk-ant-***REDACTED***',
    severity: 'critical',
    description: 'Anthropic API Key'
  },
  generic_api_key: {
    pattern: /[a-zA-Z0-9]{32,64}/g,
    mask: '***REDACTED***',
    severity: 'high',
    description: 'Potential API Key (32-64 chars)',
    contextCheck: true
  },
  
  // Tokens
  bearer_token: {
    pattern: /Bearer\s+[a-zA-Z0-9\-_]{20,}/gi,
    mask: 'Bearer ***REDACTED***',
    severity: 'critical',
    description: 'Bearer Token'
  },
  jwt_token: {
    pattern: /eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*/g,
    mask: '***JWT_REDACTED***',
    severity: 'high',
    description: 'JWT Token'
  },
  
  // Private Keys
  ssh_private_key: {
    pattern: /-----BEGIN (RSA|OPENSSH|DSA|EC) PRIVATE KEY-----[\s\S]*?-----END (RSA|OPENSSH|DSA|EC) PRIVATE KEY-----/g,
    mask: '***SSH_PRIVATE_KEY_REDACTED***',
    severity: 'critical',
    description: 'SSH Private Key'
  },
  pem_private_key: {
    pattern: /-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----/g,
    mask: '***PEM_PRIVATE_KEY_REDACTED***',
    severity: 'critical',
    description: 'PEM Private Key'
  },
  
  // Passwörter
  password_assignment: {
    pattern: /(password|passwd|pwd)\s*[=:]\s*["']?[^\s"']{8,}["']?/gi,
    mask: '$1=***REDACTED***',
    severity: 'high',
    description: 'Password in Code'
  },
  
  // Connection Strings
  db_connection: {
    pattern: /(mongodb|postgres|mysql):\/\/[^\s"']+/gi,
    mask: '$1://***REDACTED***',
    severity: 'high',
    description: 'Database Connection String'
  },
  
  // E-Mails
  email: {
    pattern: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
    mask: '***EMAIL_REDACTED***',
    severity: 'low',
    description: 'Email Address',
    optional: true
  }
};

/**
 * Analysiert Inhalt auf sensitive Daten
 */
function analyze(content, options = {}) {
  const findings = [];
  const { includeOptional = false, contextWindow = 50 } = options;
  
  for (const [type, config] of Object.entries(SENSITIVE_PATTERNS)) {
    if (config.optional && !includeOptional) continue;
    
    const matches = [...content.matchAll(config.pattern)];
    
    for (const match of matches) {
      const value = match[0];
      const index = match.index;
      
      if (config.contextCheck) {
        const context = content.substring(
          Math.max(0, index - contextWindow),
          Math.min(content.length, index + value.length + contextWindow)
        ).toLowerCase();
        
        const contextKeywords = ['api', 'key', 'token', 'secret', 'auth', 'credential'];
        if (!contextKeywords.some(kw => context.includes(kw))) {
          continue;
        }
      }
      
      findings.push({
        type,
        severity: config.severity,
        description: config.description,
        value: value.substring(0, 20) + '...',
        position: index,
        context: content.substring(
          Math.max(0, index - 30),
          Math.min(content.length, index + value.length + 30)
        ).replace(/\n/g, ' ')
      });
    }
  }
  
  return findings;
}

/**
 * Maskiert sensitive Daten im Inhalt
 */
function scrub(content, options = {}) {
  let scrubbed = content;
  const maskCount = {};
  
  for (const [type, config] of Object.entries(SENSITIVE_PATTERNS)) {
    if (config.optional && !options.includeOptional) continue;
    
    const matches = [...content.matchAll(config.pattern)];
    let count = 0;
    
    for (const match of matches) {
      const value = match[0];
      const index = match.index;
      
      if (config.contextCheck) {
        const context = content.substring(
          Math.max(0, index - 50),
          Math.min(content.length, index + value.length + 50)
        ).toLowerCase();
        
        const contextKeywords = ['api', 'key', 'token', 'secret', 'auth', 'credential'];
        if (!contextKeywords.some(kw => context.includes(kw))) {
          continue;
        }
      }
      
      count++;
    }
    
    if (count > 0) {
      scrubbed = scrubbed.replace(config.pattern, config.mask);
      maskCount[type] = count;
    }
  }
  
  return {
    scrubbed,
    maskCount,
    totalMasked: Object.values(maskCount).reduce((a, b) => a + b, 0)
  };
}

/**
 * Erstellt Bericht über gefundene sensitive Daten
 */
function report(findings) {
  if (findings.length === 0) {
    return {
      safe: true,
      summary: 'Keine sensitiven Daten gefunden',
      findings: []
    };
  }
  
  const bySeverity = {
    critical: findings.filter(f => f.severity === 'critical'),
    high: findings.filter(f => f.severity === 'high'),
    medium: findings.filter(f => f.severity === 'medium'),
    low: findings.filter(f => f.severity === 'low')
  };
  
  return {
    safe: false,
    summary: `${findings.length} potentielle Lecks gefunden`,
    bySeverity,
    findings: findings.slice(0, 10),
    recommendation: bySeverity.critical.length > 0 
      ? '⚠️ KRITISCH: Sofort bereinigen!'
      : bySeverity.high.length > 0
        ? '🔶 HOCH: Review empfohlen'
        : '🟡 NIEDRIG: Prüfen bei Gelegenheit'
  };
}

module.exports = {
  analyze,
  scrub,
  report,
  SENSITIVE_PATTERNS
};

// CLI nur wenn direkt ausgeführt
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log(`
🔒 PII Scrubber

Verwendung:
  node scrubber.js [Befehl] [Datei/Optionen]

Befehle:
  analyze <datei>     Analysiert Datei auf sensitive Daten
  scrub <datei>       Maskiert sensitive Daten
  scrub <datei> --save  Speichert bereinigte Version

Beispiele:
  node scrubber.js analyze memory/2026-04-08.md
  node scrubber.js scrub memory/2026-04-08.md
  node scrubber.js scrub memory/2026-04-08.md --save
  `);
    process.exit(0);
  }

  const command = args[0];
  const targetFile = args[1];
  const saveMode = args.includes('--save');

  if (!targetFile) {
    console.error('❌ Datei angeben');
    process.exit(1);
  }

  if (!fs.existsSync(targetFile)) {
    console.error(`❌ Datei nicht gefunden: ${targetFile}`);
    process.exit(1);
  }

  const content = fs.readFileSync(targetFile, 'utf-8');

  if (command === 'analyze') {
    const findings = analyze(content);
    const result = report(findings);
    
    console.log('\n🔍 Analyse-Ergebnis\n');
    console.log(`Status: ${result.safe ? '✅ SICHER' : '❌ LECKS GEFUNDEN'}`);
    console.log(`Befund: ${result.summary}`);
    
    if (!result.safe) {
      console.log('\n📊 Nach Schweregrad:');
      for (const [sev, items] of Object.entries(result.bySeverity)) {
        if (items.length > 0) {
          console.log(`  ${sev.toUpperCase()}: ${items.length}`);
        }
      }
      
      console.log('\n🔎 Details (Top 10):');
      for (const f of result.findings) {
        console.log(`\n  [${f.severity.toUpperCase()}] ${f.description}`);
        console.log(`  Wert: ${f.value}`);
        console.log(`  Kontext: ...${f.context}...`);
      }
      
      console.log(`\n💡 Empfehlung: ${result.recommendation}`);
    }
    
  } else if (command === 'scrub') {
    const result = scrub(content);
    
    console.log('\n🧹 Scrubbing-Ergebnis\n');
    console.log(`Gesamt maskiert: ${result.totalMasked}`);
    
    if (result.totalMasked > 0) {
      console.log('\n📊 Nach Typ:');
      for (const [type, count] of Object.entries(result.maskCount)) {
        console.log(`  ${type}: ${count}`);
      }
      
      if (saveMode) {
        const backupFile = targetFile + '.backup';
        fs.writeFileSync(backupFile, content);
        fs.writeFileSync(targetFile, result.scrubbed);
        
        console.log(`\n✅ Bereinigt und gespeichert`);
        console.log(`   Backup: ${backupFile}`);
      } else {
        console.log('\n--- BEREINIGTE VERSION (Vorschau) ---\n');
        console.log(result.scrubbed.substring(0, 1000));
        if (result.scrubbed.length > 1000) {
          console.log('\n... (truncated)');
        }
        console.log('\n---------------------------------------');
        console.log('\n💡 Verwende --save um zu speichern');
      }
    } else {
      console.log('✅ Keine sensitiven Daten gefunden');
    }
    
  } else {
    console.error(`❌ Unbekannter Befehl: ${command}`);
    process.exit(1);
  }
}