# Mission Control Dashboard - AI Coding Agent Prompts

This document contains 8 production-ready prompts for building the Mission Control Dashboard system. Each prompt is self-contained and can be given directly to an AI coding assistant.

---

## Prompt 1: BASE SYSTEM SETUP

```
You are building the foundation for a "Mission Control Dashboard" - a project management and agent orchestration system. Create the initial Next.js project structure with all necessary configurations.

## PROJECT REQUIREMENTS

**Tech Stack:**
- Next.js 14+ with App Router
- TypeScript (strict mode)
- Tailwind CSS for styling
- shadcn/ui component library
- Zustand for state management
- React Query (TanStack Query) for server state
- date-fns for date manipulation
- @dnd-kit/core for drag-and-drop (will be used by Task Board)

**Project Structure to Create:**
```
mission-control/
├── app/
│   ├── layout.tsx              # Root layout with providers
│   ├── page.tsx                # Main dashboard entry
│   ├── globals.css             # Global styles + Tailwind
│   ├── providers.tsx           # QueryClient + Zustand providers
│   └── (routes)/
│       ├── tasks/page.tsx      # Task Board
│       ├── calendar/page.tsx   # Calendar view
│       ├── projects/page.tsx   # Projects list
│       ├── memories/page.tsx   # Memory viewer
│       ├── docs/page.tsx       # Document management
│       ├── team/page.tsx       # Team/agents view
│       └── office/page.tsx     # 2D office visualization
├── components/
│   ├── ui/                     # shadcn components
│   ├── layout/
│   │   ├── Sidebar.tsx         # Navigation sidebar
│   │   ├── Header.tsx          # Top header with user info
│   │   └── MainLayout.tsx      # Wrapper for all pages
│   └── shared/
│       ├── LoadingSpinner.tsx
│       ├── ErrorBoundary.tsx
│       └── StatusBadge.tsx
├── lib/
│   ├── utils.ts                # Utility functions (cn helper)
│   ├── constants.ts            # App constants
│   └── types.ts                # Global TypeScript types
├── stores/
│   ├── useAppStore.ts          # Global app state
│   └── useUIStore.ts           # UI-specific state
├── hooks/
│   ├── useLocalStorage.ts
│   └── useDebounce.ts
└── data/
    └── mockData.ts             # Initial mock data for all components
```

**IMPLEMENTATION STEPS:**

1. **Initialize Next.js Project:**
   ```bash
   npx create-next-app@latest mission-control --typescript --tailwind --eslint --app --src-dir=false
   cd mission-control
   ```

2. **Install Dependencies:**
   ```bash
   npx shadcn@latest init --yes --defaults
   npx shadcn@latest add button card badge dialog input textarea select tabs scroll-area avatar separator dropdown-menu
   npm install zustand @tanstack/react-query date-fns @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities lucide-react
   ```

3. **Create Type Definitions** (lib/types.ts):
   ```typescript
   // Task types
   export type TaskStatus = 'backlog' | 'in-progress' | 'review' | 'done';
   export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent';
   
   export interface Task {
     id: string;
     title: string;
     description: string;
     status: TaskStatus;
     priority: TaskPriority;
     assignee?: Agent;
     projectId?: string;
     createdAt: Date;
     updatedAt: Date;
     dueDate?: Date;
     tags: string[];
     autoExecute?: boolean;
   }
   
   // Agent types
   export interface Agent {
     id: string;
     name: string;
     role: string;
     avatar?: string;
     status: 'online' | 'offline' | 'busy';
     device?: string;
     location?: string;
     skills: string[];
   }
   
   // Project types
   export interface Project {
     id: string;
     name: string;
     description: string;
     status: 'active' | 'paused' | 'completed' | 'archived';
     progress: number; // 0-100
     startDate: Date;
     endDate?: Date;
     members: Agent[];
     taskCount: number;
     completedTasks: number;
   }
   
   // Memory types
   export interface Memory {
     id: string;
     content: string;
     date: Date;
     category: string;
     tags: string[];
     source?: string;
     importance: 'low' | 'medium' | 'high';
   }
   
   // Document types
   export interface Document {
     id: string;
     title: string;
     content: string;
     category: string;
     tags: string[];
     createdAt: Date;
     updatedAt: Date;
     author?: Agent;
   }
   
   // Calendar types
   export interface CalendarEvent {
     id: string;
     title: string;
     description?: string;
     startDate: Date;
     endDate?: Date;
     type: 'task' | 'cron' | 'meeting' | 'reminder';
     taskId?: string;
     recurrence?: 'daily' | 'weekly' | 'monthly';
   }
   
   // Office/Team types
   export interface OfficePosition {
     agentId: string;
     x: number; // percentage 0-100
     y: number; // percentage 0-100
     deskId: string;
   }
   
   export interface Desk {
     id: string;
     x: number;
     y: number;
     width: number;
     height: number;
     label: string;
   }
   ```

4. **Create Mock Data** (data/mockData.ts):
   Generate comprehensive mock data for all types with at least:
   - 6 agents with different roles
   - 12 tasks across all statuses
   - 3 projects with varying progress
   - 15 memories spanning different dates
   - 8 documents in various categories
   - 10 calendar events
   - Office layout with 6 desks

5. **Create Layout Components:**
   - Sidebar with navigation links to all 7 routes
   - Header with app title "Mission Control" and user profile
   - MainLayout that wraps page content

6. **Setup Global State:**
   - useAppStore: tasks, agents, projects, memories, documents
   - useUIStore: sidebarOpen, theme, notifications

7. **Configure Tailwind:**
   Add custom colors to tailwind.config.ts:
   - primary: #3b82f6 (blue)
   - success: #22c55e (green)
   - warning: #f59e0b (amber)
   - danger: #ef4444 (red)
   - background: #0f172a (dark slate)
   - surface: #1e293b (slate)

**SUCCESS CRITERIA:**
- [ ] Project initializes without errors
- [ ] All dependencies installed
- [ ] TypeScript compiles without errors
- [ ] Navigation sidebar shows all 7 routes
- [ ] Mock data is accessible from all components
- [ ] Global state stores are properly typed
- [ ] Page routes render without errors
- [ ] Dark theme is applied by default

**DEBUGGING TIPS:**
- If shadcn init fails, try with --legacy-peer-deps
- Check tsconfig.json has strict: true
- Verify tailwind.config paths are correct
- Use `npm run build` to catch TypeScript errors early
```

---

## Prompt 2: TASK BOARD COMPONENT

```
You are building the Task Board component for the Mission Control Dashboard. This is a Kanban-style board with drag-and-drop functionality.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- @dnd-kit/core for drag-and-drop
- Zustand for state management
- shadcn/ui components (Card, Badge, Button, Dialog, etc.)
- Lucide icons

The types are already defined in lib/types.ts:
- Task, TaskStatus, TaskPriority, Agent types exist
- Mock data is available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/tasks/page.tsx

**Features to Implement:**

1. **Kanban Board Layout:**
   - 4 columns: Backlog, In Progress, Review, Done
   - Each column is a droppable area
   - Horizontal scroll on mobile, full width on desktop
   - Column headers with task count badges

2. **Task Cards:**
   - Show: title, description (truncated), assignee avatar, priority badge, tags
   - Click to open task detail modal
   - Drag handle for reordering
   - Visual priority indicator (color-coded border or badge)

3. **Drag and Drop:**
   - Use @dnd-kit/core and @dnd-kit/sortable
   - Tasks can be moved between columns (changes status)
   - Tasks can be reordered within columns
   - Smooth animations during drag
   - Visual feedback on drop zones

4. **Task Detail Modal:**
   - Full task information display
   - Edit mode for all fields
   - Status change dropdown
   - Assignee selector
   - Priority selector
   - Tags editor
   - Delete task button
   - Activity feed (placeholder for now)

5. **New Task Creation:**
   - "+ New Task" button in header
   - Opens modal with form
   - Fields: title*, description, status (default: backlog), priority, assignee, tags
   - Auto-execute checkbox (for AI tasks)

6. **Live Activity Feed (Sidebar):**
   - Shows recent task updates
   - "Task moved from X to Y"
   - "New task created"
   - Timestamps relative ("2 min ago")

7. **Filters and Search:**
   - Search by task title/description
   - Filter by assignee
   - Filter by priority
   - Filter by tags
   - Clear filters button

**DATA STRUCTURE:**
```typescript
// Use existing Zustand store or create:
interface TaskState {
  tasks: Task[];
  columns: { id: TaskStatus; title: string }[];
  activities: Activity[];
  
  // Actions
  addTask: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateTask: (id: string, updates: Partial<Task>) => void;
  deleteTask: (id: string) => void;
  moveTask: (taskId: string, newStatus: TaskStatus, newIndex: number) => void;
  reorderTasks: (status: TaskStatus, oldIndex: number, newIndex: number) => void;
  addActivity: (activity: Omit<Activity, 'id' | 'timestamp'>) => void;
}
```

**UI SPECIFICATIONS:**
- Board container: flex row, gap-4, overflow-x-auto
- Column: min-w-[300px], flex-1, bg-slate-800/50 rounded-lg
- Task card: p-4, bg-slate-700, rounded-lg, shadow-sm, hover:shadow-md
- Priority colors: urgent=red, high=orange, medium=yellow, low=green
- Status badges: use shadcn Badge with variant

**INTERACTIONS:**
- Drag task: scale(1.02), shadow-lg, opacity-90
- Drop zone active: bg-slate-700/50, border-2 border-dashed border-primary
- Card hover: translateY(-2px), shadow-md

**SUCCESS CRITERIA:**
- [ ] All 4 columns render with correct task counts
- [ ] Tasks display with all required info
- [ ] Drag and drop works between columns
- [ ] Drag and drop works within columns
- [ ] Task detail modal opens and shows all info
- [ ] New task creation works
- [ ] Task updates persist in state
- [ ] Activity feed shows updates
- [ ] Search and filters work
- [ ] Responsive on mobile (horizontal scroll)

**EXAMPLE USAGE:**
```tsx
// The page should be a default export
export default function TaskBoardPage() {
  return (
    <MainLayout>
      <TaskBoard />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- If DnD doesn't work, check DndContext wrapper is present
- Verify sensors are configured (PointerSensor)
- Check that task IDs are unique strings
- Use React DevTools to verify state updates
- Test with 20+ tasks to ensure performance
```

---

## Prompt 3: CALENDAR COMPONENT

```
You are building the Calendar component for the Mission Control Dashboard. This shows scheduled tasks, cron jobs, and events in a calendar view.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- date-fns for date manipulation
- Zustand for state management
- shadcn/ui components (Calendar, Card, Badge, Dialog, Select)
- Lucide icons

Types are defined in lib/types.ts:
- CalendarEvent, Task types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/calendar/page.tsx

**Features to Implement:**

1. **Calendar Views:**
   - Month view: Grid of days, events shown as badges
   - Week view: Time-based grid, 7 columns
   - Day view: Detailed hourly breakdown
   - View toggle buttons (Month/Week/Day)

2. **Month View:**
   - 7-column grid (Sun-Sat)
   - Day numbers in top-left
   - Events shown as colored dots/badges below
   - Today highlighted
   - Click day to see all events
   - Navigation: Previous/Next month, Today button

3. **Week View:**
   - Time slots (hourly, 8am-8pm default)
   - Events positioned by start time
   - Event duration shown by height
   - All-day events at top
   - Click event for details

4. **Day View:**
   - Similar to week but single column
   - More detail for each event
   - Time slots more granular (30min)

5. **Event Display:**
   - Color by type: task=blue, cron=purple, meeting=green, reminder=yellow
   - Show title and time
   - Tooltip on hover with full details
   - Click opens event detail modal

6. **Event Detail Modal:**
   - Full event information
   - Edit capability
   - Link to associated task (if applicable)
   - Delete event
   - Recurrence info display

7. **New Event Creation:**
   - "+ Add Event" button
   - Form with: title*, type, start date/time, end time, description, recurrence
   - Option to link to existing task
   - Cron expression builder (for cron type)

8. **Cron Job Visualization:**
   - Special styling for cron events
   - Show recurrence pattern
   - "Next run" calculation
   - Enable/disable toggle

9. **Task Confirmation UI:**
   - Upcoming tasks section (sidebar)
   - Shows tasks due soon
   - Confirm/Reschedule buttons
   - Quick actions

**DATA STRUCTURE:**
```typescript
interface CalendarState {
  events: CalendarEvent[];
  currentDate: Date;
  view: 'month' | 'week' | 'day';
  
  // Actions
  addEvent: (event: Omit<CalendarEvent, 'id'>) => void;
  updateEvent: (id: string, updates: Partial<CalendarEvent>) => void;
  deleteEvent: (id: string) => void;
  setView: (view: 'month' | 'week' | 'day') => void;
  navigateDate: (direction: 'prev' | 'next' | 'today') => void;
  goToDate: (date: Date) => void;
}
```

**UI SPECIFICATIONS:**
- Calendar container: full height, bg-slate-900
- Month grid: grid-cols-7, gap-1
- Day cell: min-h-[100px], p-2, bg-slate-800
- Event badge: text-xs, px-2, py-0.5, rounded-full
- Today: ring-2 ring-primary
- Weekend days: slightly different bg

**COLOR SCHEME:**
- Task events: bg-blue-500/20, text-blue-300, border-blue-500
- Cron events: bg-purple-500/20, text-purple-300, border-purple-500
- Meetings: bg-green-500/20, text-green-300, border-green-500
- Reminders: bg-yellow-500/20, text-yellow-300, border-yellow-500

**SUCCESS CRITERIA:**
- [ ] Month view renders correct days
- [ ] Week view shows time slots
- [ ] Day view shows hourly breakdown
- [ ] Events display in correct positions
- [ ] View switching works
- [ ] Navigation (prev/next/today) works
- [ ] Event detail modal opens
- [ ] New event creation works
- [ ] Cron jobs have special styling
- [ ] Responsive design works

**EXAMPLE USAGE:**
```tsx
export default function CalendarPage() {
  return (
    <MainLayout>
      <CalendarView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Use date-fns format/parse for all date operations
- Check timezone handling if events show wrong times
- Verify week starts on Sunday (or Monday if preferred)
- Test with events spanning multiple days
- Check leap year handling (Feb 29)
```

---

## Prompt 4: PROJECTS COMPONENT

```
You are building the Projects component for the Mission Control Dashboard. This tracks multiple projects with progress, linked resources, and status management.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- Zustand for state management
- shadcn/ui components (Card, Badge, Progress, Dialog, Tabs)
- Lucide icons
- Recharts for charts (optional)

Types are defined in lib/types.ts:
- Project, Task, Agent types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/projects/page.tsx

**Features to Implement:**

1. **Project List View:**
   - Grid of project cards
   - Each card shows: name, description, progress bar, status badge, member avatars
   - Sort by: name, progress, status, start date
   - Filter by: status, members
   - Search by name/description

2. **Project Card:**
   - Header: Project name, status badge (top-right)
   - Description (2 lines max, truncate)
   - Progress bar with percentage
   - Stats row: tasks count, completed tasks, days remaining
   - Member avatars (max 5, +N more)
   - Quick actions: Edit, Archive, View Details
   - Click card to open detail view

3. **Project Detail View:**
   - Full-width header with project info
   - Progress visualization (bar or circular)
   - Status timeline (optional)
   - Tabs: Overview, Tasks, Memories, Docs, Team

4. **Overview Tab:**
   - Project description
   - Start/end dates
   - Key metrics (task completion rate, etc.)
   - Recent activity
   - Quick stats cards

5. **Tasks Tab:**
   - List of tasks for this project
   - Status breakdown
   - Mini kanban or list view
   - Link to full task board filtered by project

6. **Memories Tab:**
   - Memories linked to this project
   - Chronological list
   - Search within project memories

7. **Docs Tab:**
   - Documents associated with project
   - Category filter
   - Quick preview

8. **Team Tab:**
   - Project members list
   - Roles and contributions
   - Add/remove members

9. **New Project Creation:**
   - "+ New Project" button
   - Modal form: name*, description, start date, end date, members
   - Template selection (optional)

10. **Project Status Management:**
    - Status: Active, Paused, Completed, Archived
    - Status change with confirmation
    - Archive removes from main view

**DATA STRUCTURE:**
```typescript
interface ProjectState {
  projects: Project[];
  selectedProject: Project | null;
  view: 'grid' | 'list';
  filters: {
    status: Project['status'][];
    search: string;
    sortBy: 'name' | 'progress' | 'startDate' | 'endDate';
  };
  
  // Actions
  addProject: (project: Omit<Project, 'id' | 'progress' | 'taskCount' | 'completedTasks'>) => void;
  updateProject: (id: string, updates: Partial<Project>) => void;
  deleteProject: (id: string) => void;
  archiveProject: (id: string) => void;
  selectProject: (project: Project | null) => void;
  addMember: (projectId: string, agentId: string) => void;
  removeMember: (projectId: string, agentId: string) => void;
  calculateProgress: (projectId: string) => number;
}
```

**UI SPECIFICATIONS:**
- Projects grid: grid-cols-1 md:grid-cols-2 lg:grid-cols-3, gap-6
- Project card: bg-slate-800, rounded-xl, p-6, hover:shadow-lg
- Progress bar: h-2, bg-slate-700, rounded-full
- Status badges:
  - Active: bg-green-500/20, text-green-300
  - Paused: bg-yellow-500/20, text-yellow-300
  - Completed: bg-blue-500/20, text-blue-300
  - Archived: bg-slate-500/20, text-slate-400

**SUCCESS CRITERIA:**
- [ ] Project grid displays all projects
- [ ] Project cards show correct info
- [ ] Progress bars are accurate
- [ ] Sorting works correctly
- [ ] Filtering works correctly
- [ ] Search finds projects
- [ ] Detail view opens with tabs
- [ ] All tabs show relevant content
- [ ] New project creation works
- [ ] Status changes persist

**EXAMPLE USAGE:**
```tsx
export default function ProjectsPage() {
  return (
    <MainLayout>
      <ProjectsView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Verify progress calculation: (completedTasks / taskCount) * 100
- Check that archived projects are filtered by default
- Ensure member avatars don't overflow (use -ml-2 for stacking)
- Test with 0 tasks (progress should be 0)
- Verify date calculations for "days remaining"
```

---

## Prompt 5: MEMORIES COMPONENT

```
You are building the Memories component for the Mission Control Dashboard. This displays agent memories organized by date with search functionality.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- date-fns for date formatting
- Zustand for state management
- shadcn/ui components (Card, Input, Badge, ScrollArea, Collapsible)
- Lucide icons

Types are defined in lib/types.ts:
- Memory, Agent types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/memories/page.tsx

**Features to Implement:**

1. **Date-Organized View:**
   - Group memories by date (Today, Yesterday, This Week, This Month, Older)
   - Chronological order within groups (newest first)
   - Date headers with memory count
   - Expandable/collapsible date groups

2. **Memory Cards:**
   - Content (full text, expandable if long)
   - Timestamp (relative: "2 hours ago", absolute on hover)
   - Category badge
   - Tags
   - Source indicator (which agent/system)
   - Importance indicator (color-coded)

3. **Search Functionality:**
   - Full-text search across memory content
   - Real-time filtering as user types
   - Highlight matching text
   - Search in tags and categories
   - Clear search button
   - "No results" state

4. **Filter Sidebar:**
   - Filter by date range (Today, Week, Month, Custom)
   - Filter by category
   - Filter by importance
   - Filter by source/agent
   - Active filter chips
   - Clear all filters

5. **Long-term Memory Section:**
   - Special section for important memories
   - Pinned/starred memories
   - Higher importance threshold
   - Quick access from sidebar

6. **Memory Detail View:**
   - Full content display
   - Metadata (date, source, category, tags)
   - Related memories (same category/tags)
   - Edit/delete actions

7. **New Memory Creation:**
   - "+ Add Memory" button
   - Form: content*, category, tags, importance
   - Auto-capture from agent actions (placeholder)

8. **Importance Levels:**
   - Low: subtle styling
   - Medium: normal styling
   - High: prominent, highlighted
   - Visual indicators (border, background, icon)

**DATA STRUCTURE:**
```typescript
interface MemoryState {
  memories: Memory[];
  filters: {
    search: string;
    dateRange: 'all' | 'today' | 'week' | 'month' | 'custom';
    categories: string[];
    importance: Memory['importance'][];
    sources: string[];
  };
  
  // Actions
  addMemory: (memory: Omit<Memory, 'id' | 'date'>) => void;
  updateMemory: (id: string, updates: Partial<Memory>) => void;
  deleteMemory: (id: string) => void;
  searchMemories: (query: string) => Memory[];
  filterMemories: (filters: MemoryState['filters']) => Memory[];
  getMemoriesByDate: () => Record<string, Memory[]>;
  getImportantMemories: () => Memory[];
}
```

**UI SPECIFICATIONS:**
- Container: max-w-4xl mx-auto, py-6
- Date group header: sticky top-0, bg-slate-900, z-10
- Memory card: bg-slate-800, rounded-lg, p-4, mb-3
- Search input: full width, with search icon
- Filter sidebar: w-64, hidden on mobile (drawer)
- Importance colors:
  - Low: border-slate-600
  - Medium: border-blue-500
  - High: border-amber-500, bg-amber-500/10

**DATE GROUPING:**
- Today: isToday(date)
- Yesterday: isYesterday(date)
- This Week: isThisWeek(date) && !isToday && !isYesterday
- This Month: isThisMonth(date) && !isThisWeek
- Older: everything else

**SUCCESS CRITERIA:**
- [ ] Memories grouped by date correctly
- [ ] Search filters in real-time
- [ ] Matching text highlighted
- [ ] Date filters work
- [ ] Category filters work
- [ ] Importance indicators visible
- [ ] Long-term memories section shows high-importance items
- [ ] Expand/collapse date groups works
- [ ] New memory creation works
- [ ] Responsive layout

**EXAMPLE USAGE:**
```tsx
export default function MemoriesPage() {
  return (
    <MainLayout>
      <MemoriesView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Use date-fns isToday, isYesterday, isThisWeek for grouping
- Debounce search input (300ms)
- Check timezone handling for date comparisons
- Test with 100+ memories for performance
- Verify highlight regex doesn't break on special characters
```

---

## Prompt 6: DOCS COMPONENT

```
You are building the Docs component for the Mission Control Dashboard. This manages documents with categories, search, and preview functionality.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- Zustand for state management
- shadcn/ui components (Card, Input, Badge, Dialog, Tabs, ScrollArea)
- Lucide icons
- react-markdown (optional, for preview)

Types are defined in lib/types.ts:
- Document, Agent types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/docs/page.tsx

**Features to Implement:**

1. **Document List View:**
   - Grid or list layout toggle
   - Document cards with: title, excerpt, category, tags, author, date
   - Sort by: title, date, category
   - Quick actions: Edit, Delete, Preview

2. **Document Card:**
   - Title (clickable)
   - Content excerpt (first 150 chars)
   - Category badge
   - Tags (max 3, +N more)
   - Author avatar + name
   - Last updated date
   - Document icon based on category

3. **Category Organization:**
   - Sidebar with category list
   - Category counts
   - Click to filter
   - "All Documents" option
   - Uncategorized section

4. **Full-Text Search:**
   - Search across title and content
   - Real-time results
   - Highlight matching terms
   - Search in tags
   - Recent searches (optional)

5. **Document Preview:**
   - Modal or side panel
   - Full content display
   - Formatted text (markdown support optional)
   - Metadata sidebar
   - Edit button

6. **Document Editor:**
   - Create new document
   - Edit existing document
   - Fields: title*, content*, category, tags
   - Auto-save draft (optional)
   - Preview mode toggle

7. **Tag Management:**
   - Tag cloud/popular tags
   - Click tag to filter
   - Add/remove tags in editor
   - Tag suggestions

8. **Document Actions:**
   - Create, Edit, Delete
   - Duplicate
   - Export (JSON/MD placeholder)
   - Archive

**DATA STRUCTURE:**
```typescript
interface DocsState {
  documents: Document[];
  categories: string[];
  filters: {
    search: string;
    category: string | null;
    tags: string[];
    sortBy: 'title' | 'date' | 'category';
    view: 'grid' | 'list';
  };
  selectedDocument: Document | null;
  
  // Actions
  addDocument: (doc: Omit<Document, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateDocument: (id: string, updates: Partial<Document>) => void;
  deleteDocument: (id: string) => void;
  duplicateDocument: (id: string) => void;
  searchDocuments: (query: string) => Document[];
  filterByCategory: (category: string | null) => Document[];
  filterByTags: (tags: string[]) => Document[];
  getAllTags: () => string[];
  getAllCategories: () => string[];
}
```

**UI SPECIFICATIONS:**
- Container: flex, h-full
- Sidebar: w-64, border-r border-slate-700
- Content area: flex-1, overflow-auto
- Document grid: grid-cols-1 md:grid-cols-2 lg:grid-cols-3
- Document card: bg-slate-800, rounded-lg, p-5
- List view: flex row items-center, border-b border-slate-700
- Search bar: sticky top-0, bg-slate-900, p-4

**CATEGORY ICONS (Lucide):**
- General: FileText
- API: Code
- Guide: BookOpen
- Meeting: Users
- Planning: Calendar
- Research: Search
- Default: File

**SUCCESS CRITERIA:**
- [ ] Document list displays correctly
- [ ] Grid/list toggle works
- [ ] Category sidebar shows all categories
- [ ] Category filter works
- [ ] Search filters documents
- [ ] Matching text highlighted
- [ ] Document preview opens
- [ ] Editor creates/edits documents
- [ ] Tags display and filter correctly
- [ ] Sorting works

**EXAMPLE USAGE:**
```tsx
export default function DocsPage() {
  return (
    <MainLayout>
      <DocsView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Debounce search for performance
- Check that excerpts don't break mid-word
- Verify tag filtering uses AND logic (all selected tags must match)
- Test with empty categories
- Ensure document IDs are unique
```

---

## Prompt 7: TEAM COMPONENT

```
You are building the Team component for the Mission Control Dashboard. This displays agent cards, roles, mission statement, and team organization.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- Zustand for state management
- shadcn/ui components (Card, Avatar, Badge, Dialog, Tabs)
- Lucide icons

Types are defined in lib/types.ts:
- Agent types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/team/page.tsx

**Features to Implement:**

1. **Mission Statement Display:**
   - Prominent header section
   - Editable mission statement
   - Last updated timestamp
   - Save/Edit toggle

2. **Agent Cards Grid:**
   - Grid of agent cards
   - Each card shows:
     - Avatar (with online status indicator)
     - Name
     - Role/title
     - Status badge (online/offline/busy)
     - Skills/tags
     - Device info (optional)
     - Location (optional)

3. **Agent Detail Modal:**
   - Full agent profile
   - Larger avatar
   - Complete info: name, role, status, skills, device, location
   - Assigned tasks count
   - Recent activity (placeholder)
   - Edit/Delete actions

4. **Agent Status Management:**
   - Status indicators with colors:
     - Online: green
     - Offline: gray
     - Busy: amber
   - Status change dropdown
   - Last seen timestamp for offline

5. **Role Organization:**
   - Group agents by role (optional view)
   - Role badges/categories
   - Role-based filtering

6. **Skills Display:**
   - Skills as badges on cards
   - Skills list in detail view
   - Filter by skill

7. **Team Statistics:**
   - Total agents count
   - Online agents count
   - Agents by role breakdown
   - Skills distribution (optional chart)

8. **New Agent Creation:**
   - "+ Add Agent" button
   - Form: name*, role*, skills, device, location
   - Avatar upload (placeholder URL input)

9. **Agent Actions:**
   - Edit agent info
   - Change status
   - Remove agent
   - Assign to tasks (link to task board)

**DATA STRUCTURE:**
```typescript
interface TeamState {
  agents: Agent[];
  missionStatement: string;
  missionLastUpdated: Date;
  filters: {
    status: Agent['status'][];
    role: string[];
    skills: string[];
    search: string;
  };
  selectedAgent: Agent | null;
  
  // Actions
  addAgent: (agent: Omit<Agent, 'id'>) => void;
  updateAgent: (id: string, updates: Partial<Agent>) => void;
  deleteAgent: (id: string) => void;
  updateMissionStatement: (statement: string) => void;
  setAgentStatus: (id: string, status: Agent['status']) => void;
  selectAgent: (agent: Agent | null) => void;
  getOnlineAgents: () => Agent[];
  getAgentsByRole: () => Record<string, Agent[]>;
  getAllSkills: () => string[];
}
```

**UI SPECIFICATIONS:**
- Mission section: bg-gradient-to-r from-blue-900 to-slate-900, p-8, rounded-xl
- Agent grid: grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4, gap-6
- Agent card: bg-slate-800, rounded-xl, p-6, hover:shadow-lg
- Avatar: w-16 h-16, rounded-full
- Status indicator: w-3 h-3, rounded-full, absolute bottom-0 right-0, ring-2 ring-slate-800
- Skills: flex wrap gap-2, text-xs

**STATUS COLORS:**
- Online: bg-green-500
- Offline: bg-slate-500
- Busy: bg-amber-500

**SUCCESS CRITERIA:**
- [ ] Mission statement displays prominently
- [ ] Agent cards show all info
- [ ] Status indicators are correct colors
- [ ] Online/offline status visible
- [ ] Agent detail modal opens
- [ ] New agent creation works
- [ ] Agent editing works
- [ ] Status changes persist
- [ ] Skills display correctly
- [ ] Filtering by status/role works

**EXAMPLE USAGE:**
```tsx
export default function TeamPage() {
  return (
    <MainLayout>
      <TeamView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Verify avatar images load (use fallback initials)
- Check status indicator positioning (absolute within relative)
- Ensure agent IDs are unique
- Test with long names (truncate if needed)
- Verify skill badges don't overflow card
```

---

## Prompt 8: OFFICE COMPONENT

```
You are building the Office component for the Mission Control Dashboard. This is a 2D visualization showing agents working at their desks in real-time.

## CONTEXT
This component runs in a Next.js 14 app with:
- TypeScript and Tailwind CSS
- HTML5 Canvas OR CSS-based positioning
- Zustand for state management
- shadcn/ui components (Card, Tooltip, Badge)
- Lucide icons

Types are defined in lib/types.ts:
- Agent, OfficePosition, Desk types exist
- Mock data available in data/mockData.ts

## REQUIREMENTS

**Create the file:** app/(routes)/office/page.tsx

**Features to Implement:**

1. **2D Office Visualization:**
   - Office floor plan view
   - Desks positioned in the space
   - Agent avatars at their assigned desks
   - Background: grid pattern or office floor texture
   - Walls/room boundaries (optional)

2. **Desk Layout:**
   - Predefined desk positions
   - Desk shapes: rectangular or L-shaped
   - Desk labels/numbers
   - Visual distinction for occupied/empty desks

3. **Agent Avatars:**
   - Circular avatars positioned at desks
   - Status indicator ring (online/offline/busy)
   - Name label below avatar
   - Role label (smaller, optional)

4. **Real-time Position Updates:**
   - Agents can move between desks (simulated)
   - Smooth transitions/animations
   - Position history (optional)

5. **Interactive Elements:**
   - Click agent for info tooltip/modal
   - Hover shows quick info (name, role, status, current task)
   - Click desk to see who's assigned

6. **Agent Info Panel:**
   - Sidebar or floating panel
   - Shows selected agent details
   - Current activity/status
   - Assigned tasks

7. **Office Controls:**
   - Zoom in/out buttons
   - Reset view button
   - Pan/drag to move around (for large offices)
   - Mini-map (optional)

8. **Activity Indicators:**
   - Visual cues for active agents
   - Typing indicator animation
   - Status change animations
   - Recent activity log

**IMPLEMENTATION OPTIONS:**

**Option A: CSS-based (Recommended for simplicity)**
```tsx
// Use absolute positioning within a relative container
<div className="relative w-full h-[600px] bg-slate-800 overflow-hidden">
  {/* Grid background */}
  <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-[size:20px_20px]" />
  
  {/* Desks */}
  {desks.map(desk => (
    <div 
      key={desk.id}
      className="absolute bg-slate-700 rounded"
      style={{ left: `${desk.x}%`, top: `${desk.y}%`, width: desk.width, height: desk.height }}
    />
  ))}
  
  {/* Agents */}
  {agents.map(agent => (
    <div 
      key={agent.id}
      className="absolute transition-all duration-500"
      style={{ left: `${agent.x}%`, top: `${agent.y}%` }}
    >
      <AgentAvatar agent={agent} />
    </div>
  ))}
</div>
```

**Option B: Canvas-based (For complex animations)**
- Use HTML5 Canvas API
- More control over rendering
- Better for many agents
- Requires manual hit detection

**DATA STRUCTURE:**
```typescript
interface OfficeState {
  desks: Desk[];
  agentPositions: OfficePosition[];
  selectedAgent: Agent | null;
  zoom: number;
  pan: { x: number; y: number };
  
  // Actions
  moveAgent: (agentId: string, deskId: string) => void;
  updatePosition: (agentId: string, x: number, y: number) => void;
  selectAgent: (agent: Agent | null) => void;
  setZoom: (zoom: number) => void;
  setPan: (pan: { x: number; y: number }) => void;
  resetView: () => void;
}
```

**UI SPECIFICATIONS:**
- Container: relative, h-[600px] or full height, bg-slate-900
- Grid: 20px squares, subtle lines
- Desk: bg-slate-700, rounded-md, shadow
- Agent avatar: w-12 h-12, rounded-full
- Status ring: 3px border
- Name label: text-xs, bg-slate-800/80, px-2, py-0.5, rounded

**OFFICE LAYOUT (Example):**
```typescript
const desks: Desk[] = [
  { id: 'desk-1', x: 10, y: 20, width: 80, height: 60, label: 'Desk 1' },
  { id: 'desk-2', x: 30, y: 20, width: 80, height: 60, label: 'Desk 2' },
  { id: 'desk-3', x: 50, y: 20, width: 80, height: 60, label: 'Desk 3' },
  { id: 'desk-4', x: 10, y: 60, width: 80, height: 60, label: 'Desk 4' },
  { id: 'desk-5', x: 30, y: 60, width: 80, height: 60, label: 'Desk 5' },
  { id: 'desk-6', x: 50, y: 60, width: 80, height: 60, label: 'Desk 6' },
];
```

**ANIMATIONS:**
- Agent movement: transition-all duration-500 ease-out
- Status changes: pulse animation
- Hover: scale(1.1)

**SUCCESS CRITERIA:**
- [ ] Office floor plan renders
- [ ] Desks positioned correctly
- [ ] Agent avatars at correct positions
- [ ] Status indicators visible
- [ ] Hover shows agent info
- [ ] Click selects agent
- [ ] Info panel shows details
- [ ] Zoom controls work
- [ ] Agent movement animated
- [ ] Responsive layout

**EXAMPLE USAGE:**
```tsx
export default function OfficePage() {
  return (
    <MainLayout>
      <OfficeView />
    </MainLayout>
  );
}
```

**DEBUGGING GUIDANCE:**
- Verify percentage positions (0-100) work with container
- Check that avatars don't overflow container
- Test zoom functionality doesn't break positioning
- Ensure tooltips don't get cut off
- For canvas: verify device pixel ratio for crisp rendering
- Test with 10+ agents for performance
```

---

## Summary

These 8 prompts provide complete instructions for building the Mission Control Dashboard:

1. **Base System Setup** - Project initialization and shared infrastructure
2. **Task Board** - Kanban board with drag-and-drop
3. **Calendar** - Event scheduling and cron job visualization
4. **Projects** - Project tracking with progress
5. **Memories** - Date-organized memory viewer
6. **Docs** - Document management with search
7. **Team** - Agent organization and mission statement
8. **Office** - 2D visualization of agents working

Each prompt is self-contained and can be given directly to an AI coding assistant for implementation.
