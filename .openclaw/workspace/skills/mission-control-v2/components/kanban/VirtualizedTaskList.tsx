import { useRef, useCallback } from 'react';
import { Task } from '@/types';
import { TaskCard } from './TaskCard';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { FixedSizeList: List } = require('react-window');

interface VirtualizedTaskListProps {
  tasks: Task[];
  columnId: string;
}

// Row renderer for react-window
const TaskRow = ({
  index,
  style,
  data,
}: {
  index: number;
  style: React.CSSProperties;
  data: { tasks: Task[] };
}) => {
  const task = data.tasks[index];
  
  return (
    <div style={style} className="px-2 py-1">
      <TaskCard task={task} />
    </div>
  );
};

export function VirtualizedTaskList({ tasks, columnId }: VirtualizedTaskListProps) {
  const listRef = useRef<any>(null);

  // Estimate item height (TaskCard is roughly 120-150px depending on content)
  const ITEM_HEIGHT = 140;
  const MAX_LIST_HEIGHT = 600;
  
  const listHeight = Math.min(tasks.length * ITEM_HEIGHT, MAX_LIST_HEIGHT);

  return (
    <div className="flex-1 min-h-0">
      {tasks.length > 20 ? (
        // Use virtualization for large lists
        <List
          ref={listRef}
          height={listHeight}
          itemCount={tasks.length}
          itemSize={ITEM_HEIGHT}
          itemData={{ tasks }}
          width="100%"
          overscanCount={3}
        >
          {TaskRow}
        </List>
      ) : (
        // Regular list for small datasets
        <div className="space-y-2">
          {tasks.map((task) => (
            <TaskCard key={task.id} task={task} />
          ))}
        </div>
      )}
    </div>
  );
}

// Hook for using virtualization in any list
export function useVirtualization(itemCount: number, itemHeight: number = 72) {
  const listRef = useRef<any>(null);
  const MAX_HEIGHT = 600;
  
  const shouldVirtualize = itemCount > 20;
  const listHeight = Math.min(itemCount * itemHeight, MAX_HEIGHT);

  const scrollToItem = useCallback((index: number) => {
    if (listRef.current) {
      listRef.current.scrollToItem(index, 'center');
    }
  }, []);

  const scrollToTop = useCallback(() => {
    if (listRef.current) {
      listRef.current.scrollTo(0);
    }
  }, []);

  const scrollToBottom = useCallback(() => {
    if (listRef.current) {
      listRef.current.scrollToItem(itemCount - 1, 'end');
    }
  }, [itemCount]);

  return {
    listRef,
    shouldVirtualize,
    listHeight,
    itemHeight,
    scrollToItem,
    scrollToTop,
    scrollToBottom,
  };
}

// Generic virtualized list component
interface VirtualListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => React.ReactNode;
  itemHeight: number;
  maxHeight?: number;
  className?: string;
  overscanCount?: number;
}

export function VirtualList<T extends { id: string }>({
  items,
  renderItem,
  itemHeight,
  maxHeight = 600,
  className,
  overscanCount = 3,
}: VirtualListProps<T>) {
  const listRef = useRef<any>(null);

  const listHeight = Math.min(items.length * itemHeight, maxHeight);

  const Row = useCallback(
    ({ index, style }: { index: number; style: React.CSSProperties }) => (
      <div style={style}>{renderItem(items[index], index)}</div>
    ),
    [items, renderItem]
  );

  if (items.length <= 20) {
    return (
      <div className={className}>
        {items.map((item, index) => renderItem(item, index))}
      </div>
    );
  }

  return (
    <List
      ref={listRef}
      height={listHeight}
      itemCount={items.length}
      itemSize={itemHeight}
      width="100%"
      overscanCount={overscanCount}
      className={className}
    >
      {Row}</List>
  );
}
