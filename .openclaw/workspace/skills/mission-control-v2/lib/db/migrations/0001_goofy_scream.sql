CREATE TABLE `activities` (
	`id` text PRIMARY KEY NOT NULL,
	`type` text NOT NULL,
	`actor_id` text NOT NULL,
	`actor_type` text NOT NULL,
	`actor_name` text NOT NULL,
	`target_type` text NOT NULL,
	`target_id` text NOT NULL,
	`target_name` text NOT NULL,
	`action` text NOT NULL,
	`metadata` text DEFAULT '{}',
	`timestamp` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `agents` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`role` text NOT NULL,
	`avatar` text,
	`status` text DEFAULT 'idle' NOT NULL,
	`current_task_id` text,
	`device_type` text,
	`device_os` text,
	`capabilities` text DEFAULT '[]',
	`tasks_completed` integer DEFAULT 0,
	`avg_completion_time` real,
	`success_rate` real,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `documents` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`content` text NOT NULL,
	`category` text NOT NULL,
	`tags` text DEFAULT '[]',
	`project_id` text,
	`created_by` text NOT NULL,
	`updated_by` text NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	`version` integer DEFAULT 1 NOT NULL,
	`is_archived` integer DEFAULT false
);
--> statement-breakpoint
CREATE TABLE `memories` (
	`id` text PRIMARY KEY NOT NULL,
	`content` text NOT NULL,
	`type` text NOT NULL,
	`date` integer NOT NULL,
	`tags` text DEFAULT '[]',
	`importance` integer DEFAULT 5 NOT NULL,
	`project_id` text,
	`task_id` text,
	`agent_id` text,
	`embedding` text,
	`source` text NOT NULL,
	`related_memories` text DEFAULT '[]',
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `projects` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`description` text NOT NULL,
	`status` text NOT NULL,
	`progress` integer DEFAULT 0 NOT NULL,
	`color` text DEFAULT '#3b82f6' NOT NULL,
	`start_date` integer,
	`target_date` integer,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `scheduled_jobs` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`cron_expression` text NOT NULL,
	`task_template` text NOT NULL,
	`is_active` integer DEFAULT true,
	`last_run` integer,
	`next_run` integer,
	`run_count` integer DEFAULT 0,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
ALTER TABLE `tasks` ADD `project_id` text;--> statement-breakpoint
ALTER TABLE `tasks` ADD `due_date` integer;--> statement-breakpoint
ALTER TABLE `tasks` ADD `estimated_hours` real;--> statement-breakpoint
ALTER TABLE `tasks` ADD `subtasks` text DEFAULT '[]';--> statement-breakpoint
ALTER TABLE `tasks` ADD `metadata` text DEFAULT '{}';