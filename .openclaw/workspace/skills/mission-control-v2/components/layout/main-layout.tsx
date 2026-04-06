'use client';

import React, { useState, createContext, useContext, ReactNode } from 'react';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import {
  Kanban, Calendar, FolderKanban, FileText, Users, BarChart3, Building2
} from 'lucide-react';

const SidebarContext = createContext({
  isOpen: true,
  toggle: () => {},
});

export const useSidebar = () => useContext(SidebarContext);

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: BarChart3 },
  { name: "Tasks", href: "/tasks", icon: Kanban },
  { name: "Calendar", href: "/calendar", icon: Calendar },
  { name: "Projects", href: "/projects", icon: FolderKanban },
  { name: "Documents", href: "/docs", icon: FileText },
  { name: "Team", href: "/team", icon: Users },
  { name: "Office", href: "/office", icon: Building2 },
];

export function MainLayout({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(true);
  const pathname = usePathname();

  return (
    <SidebarContext.Provider value={{ isOpen, toggle: () => setIsOpen(!isOpen) }}>
      <div className="min-h-screen bg-[#0a0a0a]">
        {/* Sidebar */}
        <aside
          className={cn(
            'fixed left-0 top-0 h-full bg-[#0a0a0a] border-r border-white/[0.06] transition-all duration-300 z-50',
            isOpen ? 'w-60' : 'w-16'
          )}
        >
          <div className="h-14 flex items-center px-4 border-b border-white/[0.06]">
            {isOpen && (
              <span className="font-semibold text-white/90">Mission Control</span>
            )}
          </div>

          <button
            onClick={() => setIsOpen(!isOpen)}
            className="absolute -right-3 top-16 w-6 h-6 bg-purple-500 rounded-full flex items-center justify-center text-white text-xs"
          >
            {isOpen ? '←' : '→'}
          </button>

          <nav className="p-2 space-y-1 mt-4">
            {navigation.map((item) => (
              <a
                key={item.name}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors',
                  pathname === item.href
                    ? 'bg-purple-500/20 text-purple-400'
                    : 'text-white/60 hover:text-white hover:bg-white/[0.04]'
                )}
                title={!isOpen ? item.name : undefined}
              >
                <item.icon className="w-5 h-5" />
                {isOpen && <span className="text-sm">{item.name}</span>}
              </a>
            ))}
          </nav>
        </aside>

        <main
          className={cn(
            'transition-all duration-300',
            isOpen ? 'ml-60' : 'ml-16'
          )}
        >
          <header className="h-14 border-b border-white/[0.06] flex items-center px-6 sticky top-0 bg-[#0a0a0a]/95 z-40">
            <h1 className="text-lg font-semibold text-white/90">
              {navigation.find(n => n.href === pathname)?.name}
            </h1>
          </header>
          
          <div className="p-6">{children}</div>
        </main>
      </div>
    </SidebarContext.Provider>
  );
}
