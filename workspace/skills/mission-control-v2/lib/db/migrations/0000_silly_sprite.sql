CREATE TABLE `tasks` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`description` text NOT NULL,
	`status` text NOT NULL,
	`priority` text NOT NULL,
	`assignee_id` text NOT NULL,
	`assignee_type` text NOT NULL,
	`assignee_name` text NOT NULL,
	`tags` text DEFAULT '[]',
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
