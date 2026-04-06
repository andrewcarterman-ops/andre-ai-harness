'use client';

import { useEffect, useCallback } from 'react';
import { useTaskStore } from '@/stores/taskStore';
import { useActivityStore } from '@/stores/activityStore';

export function useRealtime() {
  const { fetchTasks } = useTaskStore();
  const { addActivity } = useActivityStore();

  const connect = useCallback(() => {
    const eventSource = new EventSource('/api/realtime');

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        if (data.type === 'task-update') {
          // Refresh tasks when someone else updates
          fetchTasks();
        }
        
        if (data.type === 'activity') {
          addActivity(data.payload);
        }
      } catch (e) {
        console.error('Failed to parse SSE message:', e);
      }
    };

    eventSource.onerror = () => {
      console.log('SSE connection error, reconnecting...');
      eventSource.close();
      // Reconnect after 3 seconds
      setTimeout(connect, 3000);
    };

    return () => {
      eventSource.close();
    };
  }, [fetchTasks, addActivity]);

  useEffect(() => {
    const cleanup = connect();
    return cleanup;
  }, [connect]);
}
