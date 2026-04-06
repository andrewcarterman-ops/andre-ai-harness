"use client"

import { useEffect, useState, useCallback } from "react"
import FullCalendar from "@fullcalendar/react"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin, { DateClickArg } from "@fullcalendar/interaction"
import { EventClickArg, EventDropArg } from "@fullcalendar/core"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle,
  DialogFooter
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { CalendarEvent, Task } from "@/types"
import { useTaskStore } from "@/stores/taskStore"
import { format, parseISO } from "date-fns"
import { Calendar as CalendarIcon, Clock, CheckCircle2 } from "lucide-react"

interface CalendarEventExtended {
  id: string
  title: string
  start: string
  end?: string
  backgroundColor?: string
  borderColor?: string
  textColor?: string
  extendedProps: {
    type: 'task' | 'cron' | 'meeting' | 'reminder'
    description?: string
    taskId?: string
    status?: string
  }
}

interface CalendarViewProps {
  className?: string
}

export function CalendarView({ className }: CalendarViewProps) {
  const { tasks, updateTask } = useTaskStore()
  const [events, setEvents] = useState<CalendarEventExtended[]>([])
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [selectedEvent, setSelectedEvent] = useState<CalendarEventExtended | null>(null)
  const [newEventTitle, setNewEventTitle] = useState("")
  const [newEventType, setNewEventType] = useState<'cron' | 'meeting' | 'reminder'>('meeting')

  // Convert tasks to calendar events
  useEffect(() => {
    const taskEvents: CalendarEventExtended[] = tasks
      .filter(task => task.dueDate || task.scheduledAt)
      .map(task => {
        const date = task.scheduledAt || task.dueDate
        const statusColors: Record<string, string> = {
          backlog: '#6b7280',
          todo: '#3b82f6',
          in_progress: '#f59e0b',
          review: '#8b5cf6',
          done: '#10b981',
        }
        
        return {
          id: task.id,
          title: task.title,
          start: date ? new Date(date).toISOString() : new Date().toISOString(),
          backgroundColor: statusColors[task.status] || '#6b7280',
          borderColor: statusColors[task.status] || '#6b7280',
          textColor: '#ffffff',
          extendedProps: {
            type: 'task' as const,
            description: task.description,
            taskId: task.id,
            status: task.status,
          },
        }
      })

    setEvents(taskEvents)
  }, [tasks])

  const handleDateClick = useCallback((arg: DateClickArg) => {
    setSelectedDate(arg.date)
    setSelectedEvent(null)
    setNewEventTitle("")
    setIsDialogOpen(true)
  }, [])

  const handleEventClick = useCallback((arg: EventClickArg) => {
    const event = events.find(e => e.id === arg.event.id)
    if (event) {
      setSelectedEvent(event)
      setNewEventTitle(event.title)
      setIsDialogOpen(true)
    }
  }, [events])

  const handleEventDrop = useCallback(async (arg: EventDropArg) => {
    const taskId = arg.event.id
    const newDate = arg.event.start
    
    if (taskId && newDate) {
      await updateTask(taskId, { 
        scheduledAt: newDate,
        dueDate: newDate 
      })
    }
  }, [updateTask])

  const handleCreateEvent = async () => {
    if (!newEventTitle || !selectedDate) return

    // Create a task with scheduled date
    const response = await fetch('/api/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: newEventTitle,
        description: '',
        status: 'todo',
        priority: 'medium',
        scheduledAt: selectedDate.toISOString(),
        assignee: { id: 'user-1', type: 'user', name: 'You' },
      }),
    })

    if (response.ok) {
      setIsDialogOpen(false)
      setNewEventTitle("")
      // Refresh tasks
      window.location.reload()
    }
  }

  const handleUpdateTaskStatus = async (taskId: string, newStatus: string) => {
    await updateTask(taskId, { status: newStatus as Task['status'] })
    setIsDialogOpen(false)
  }

  return (
    <div className={className}>
      <Card className="bg-white/[0.02] border-white/[0.06] p-4">
        <div className="h-[calc(100vh-250px)]">
          <FullCalendar
            plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
            initialView="dayGridMonth"
            headerToolbar={{
              left: 'prev,next today',
              center: 'title',
              right: 'dayGridMonth,timeGridWeek,timeGridDay',
            }}
            events={events}
            dateClick={handleDateClick}
            eventClick={handleEventClick}
            editable={true}
            droppable={true}
            eventDrop={handleEventDrop}
            selectable={true}
            selectMirror={true}
            dayMaxEvents={true}
            weekends={true}
            slotMinTime="06:00:00"
            slotMaxTime="22:00:00"
            allDaySlot={true}
            height="100%"
            themeSystem="standard"
            eventClassNames="cursor-pointer"
            buttonText={{
              today: 'Today',
              month: 'Month',
              week: 'Week',
              day: 'Day',
            }}
            customButtons={{
              today: {
                text: 'Today',
                click: () => {
                  const calendarApi = (document.querySelector('.fc') as any)?.__vueParentComponent?.refs?.calendar?.getApi()
                  calendarApi?.today()
                }
              }
            }}
          />
        </div>
      </Card>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="bg-[#1a1a1a] border-white/[0.08] text-white">
          <DialogHeader>
            <DialogTitle>
              {selectedEvent ? 'Event Details' : 'Create Event'}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {selectedEvent?.extendedProps.type === 'task' ? (
              <>
                <div className="flex items-start gap-3 p-3 rounded-lg bg-white/[0.04]">
                  <CheckCircle2 className="w-5 h-5 text-purple-400 mt-0.5" />
                  <div className="flex-1">
                    <p className="font-medium text-white/90">{selectedEvent.title}</p>
                    <p className="text-sm text-white/50 mt-1">
                      {selectedEvent.extendedProps.description}
                    </p>
                    <div className="flex items-center gap-4 mt-3 text-xs text-white/40">
                      <span className="flex items-center gap-1">
                        <CalendarIcon className="w-3 h-3" />
                        {format(parseISO(selectedEvent.start), 'MMM d, yyyy')}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {selectedEvent.extendedProps.status}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-white/60">Update Status</Label>
                  <Select 
                    value={selectedEvent.extendedProps.status}
                    onValueChange={(value) => handleUpdateTaskStatus(selectedEvent.id, value)}
                  >
                    <SelectTrigger className="bg-white/[0.04] border-white/[0.08]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#1a1a1a] border-white/[0.08]">
                      <SelectItem value="backlog">Backlog</SelectItem>
                      <SelectItem value="todo">To Do</SelectItem>
                      <SelectItem value="in_progress">In Progress</SelectItem>
                      <SelectItem value="review">Review</SelectItem>
                      <SelectItem value="done">Done</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </>
            ) : (
              <>
                <div className="space-y-2">
                  <Label htmlFor="title" className="text-white/60">Title</Label>
                  <Input
                    id="title"
                    value={newEventTitle}
                    onChange={(e) => setNewEventTitle(e.target.value)}
                    placeholder="Enter event title..."
                    className="bg-white/[0.04] border-white/[0.08]"
                  />
                </div>

                <div className="space-y-2">
                  <Label className="text-white/60">Type</Label>
                  <Select value={newEventType} onValueChange={(v: any) => setNewEventType(v)}>
                    <SelectTrigger className="bg-white/[0.04] border-white/[0.08]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#1a1a1a] border-white/[0.08]">
                      <SelectItem value="meeting">Meeting</SelectItem>
                      <SelectItem value="reminder">Reminder</SelectItem>
                      <SelectItem value="cron">Recurring</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {selectedDate && (
                  <div className="flex items-center gap-2 text-sm text-white/50">
                    <CalendarIcon className="w-4 h-4" />
                    {format(selectedDate, 'MMMM d, yyyy')}
                  </div>
                )}
              </>
            )}
          </div>

          <DialogFooter>
            {!selectedEvent?.extendedProps.type && (
              <Button 
                onClick={handleCreateEvent}
                className="bg-purple-500 hover:bg-purple-600"
              >
                Create Task
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
