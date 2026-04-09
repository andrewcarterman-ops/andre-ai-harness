/**
 * Obsidian Bridge
 * Bidirectional sync with Obsidian Second Brain
 * 
 * @module ObsidianBridge
 * @version 1.0.0
 */

import { EventEmitter } from 'events';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface ObsidianConfig {
  vaultPath: string;
  sync: {
    mode: 'bidirectional' | 'to_obsidian' | 'from_obsidian';
    interval: number; // seconds
    onChange: boolean;
  };
  mapping: {
    sessions: string;
    insights: string;
    errors: string;
    skills: string;
  };
  templates: {
    session: string;
    insight: string;
    error: string;
  };
}

export interface SyncChange {
  type: 'create' | 'update' | 'delete';
  source: 'obsidian' | 'harness';
  filePath: string;
  timestamp: Date;
}

export enum ConflictStrategy {
  TIMESTAMP_WINS = 'timestamp_wins',
  SOURCE_WINS = 'source_wins',
  MERGE = 'merge',
  MANUAL = 'manual',
}

export interface SyncResult {
  success: boolean;
  changes: SyncChange[];
  conflicts: Array<{
    file: string;
    strategy: ConflictStrategy;
    resolution: string;
  }>;
}

export class ObsidianBridge extends EventEmitter {
  private config: ObsidianConfig;
  private syncInterval: NodeJS.Timeout | null;
  private lastSync: Date;
  private watching: boolean;

  constructor(config: ObsidianConfig) {
    super();
    this.config = config;
    this.syncInterval = null;
    this.lastSync = new Date(0);
    this.watching = false;
  }

  /**
   * Initialize the bridge
   */
  async initialize(): Promise<void> {
    // Ensure vault directories exist
    await this.ensureDirectories();
    
    this.emit('initialized');
  }

  /**
   * Start automatic sync
   */
  start(): void {
    if (this.syncInterval) return;

    this.syncInterval = setInterval(async () => {
      await this.sync();
    }, this.config.sync.interval * 1000);

    if (this.config.sync.onChange) {
      this.startWatching();
    }

    this.emit('started');
  }

  /**
   * Stop automatic sync
   */
  stop(): void {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }

    this.stopWatching();
    this.emit('stopped');
  }

  /**
   * Perform sync
   */
  async sync(): Promise<SyncResult> {
    const changes: SyncChange[] = [];
    const conflicts: SyncResult['conflicts'] = [];

    try {
      this.emit('sync:started');

      // Sync sessions
      const sessionChanges = await this.syncSessions();
      changes.push(...sessionChanges);

      // Sync insights
      const insightChanges = await this.syncInsights();
      changes.push(...insightChanges);

      // Sync errors
      const errorChanges = await this.syncErrors();
      changes.push(...errorChanges);

      // Sync skills
      const skillChanges = await this.syncSkills();
      changes.push(...skillChanges);

      this.lastSync = new Date();
      this.emit('sync:completed', changes);

      return {
        success: true,
        changes,
        conflicts,
      };

    } catch (error) {
      this.emit('sync:error', error);
      return {
        success: false,
        changes,
        conflicts,
      };
    }
  }

  /**
   * Write session to Obsidian
   */
  async writeSession(sessionData: {
    id: string;
    date: Date;
    content: string;
    tags: string[];
  }): Promise<void> {
    const fileName = `${sessionData.date.toISOString().split('T')[0]}-${sessionData.id}.md`;
    const filePath = path.join(
      this.config.vaultPath,
      this.config.mapping.sessions,
      fileName
    );

    const content = this.formatSessionNote(sessionData);
    await this.writeFile(filePath, content);

    this.emit('session:written', filePath);
  }

  /**
   * Write insight to Obsidian
   */
  async writeInsight(insightData: {
    id: string;
    title: string;
    content: string;
    confidence: number;
    tags: string[];
    created: Date;
  }): Promise<void> {
    const fileName = `${insightData.title.toLowerCase().replace(/\s+/g, '-')}.md`;
    const filePath = path.join(
      this.config.vaultPath,
      this.config.mapping.insights,
      fileName
    );

    const content = this.formatInsightNote(insightData);
    await this.writeFile(filePath, content);

    this.emit('insight:written', filePath);
  }

  /**
   * Read file from Obsidian
   */
  async readFile(relativePath: string): Promise<string> {
    const fullPath = path.join(this.config.vaultPath, relativePath);
    return fs.readFile(fullPath, 'utf-8');
  }

  /**
   * Get all files in a directory
   */
  async listFiles(directory: string): Promise<string[]> {
    const fullPath = path.join(this.config.vaultPath, directory);
    
    try {
      const entries = await fs.readdir(fullPath, { withFileTypes: true });
      return entries
        .filter(entry => entry.isFile() && entry.name.endsWith('.md'))
        .map(entry => entry.name);
    } catch {
      return [];
    }
  }

  /**
   * Get last sync time
   */
  getLastSync(): Date {
    return this.lastSync;
  }

  // Private methods
  private async ensureDirectories(): Promise<void> {
    const dirs = [
      this.config.mapping.sessions,
      this.config.mapping.insights,
      this.config.mapping.errors,
      this.config.mapping.skills,
    ];

    for (const dir of dirs) {
      const fullPath = path.join(this.config.vaultPath, dir);
      await fs.mkdir(fullPath, { recursive: true });
    }
  }

  private async syncSessions(): Promise<SyncChange[]> {
    // Implementation would sync session files
    return [];
  }

  private async syncInsights(): Promise<SyncChange[]> {
    // Implementation would sync insight files
    return [];
  }

  private async syncErrors(): Promise<SyncChange[]> {
    // Implementation would sync error files
    return [];
  }

  private async syncSkills(): Promise<SyncChange[]> {
    // Implementation would sync skill files
    return [];
  }

  private async writeFile(filePath: string, content: string): Promise<void> {
    await fs.mkdir(path.dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, content, 'utf-8');
  }

  private formatSessionNote(sessionData: {
    id: string;
    date: Date;
    content: string;
    tags: string[];
  }): string {
    return `---
id: ${sessionData.id}
date: ${sessionData.date.toISOString()}
tags: [${sessionData.tags.map(t => `"${t}"`).join(', ')}]
---

# Session ${sessionData.date.toLocaleDateString()}

${sessionData.content}
`;
  }

  private formatInsightNote(insightData: {
    id: string;
    title: string;
    content: string;
    confidence: number;
    tags: string[];
    created: Date;
  }): string {
    return `---
id: ${insightData.id}
confidence: ${insightData.confidence}
created: ${insightData.created.toISOString()}
tags: [${insightData.tags.map(t => `"${t}"`).join(', ')}]
---

# ${insightData.title}

${insightData.content}
`;
  }

  private startWatching(): void {
    if (this.watching) return;
    this.watching = true;
    // File watching implementation would go here
  }

  private stopWatching(): void {
    this.watching = false;
  }
}

export default ObsidianBridge;
