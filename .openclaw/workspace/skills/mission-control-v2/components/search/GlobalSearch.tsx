'use client';

import { useState } from 'react';
import { Search, Command } from 'lucide-react';

export function GlobalSearch() {
  const [isOpen, setIsOpen] = useState(false);

  if (!isOpen) {
    return (
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 px-3 py-1.5 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/40 hover:text-white/60 hover:bg-white/[0.04] transition-colors w-full"
      >
        <Search className="w-4 h-4" />
        <span className="text-sm hidden sm:inline">Search...</span>
        <kbd className="hidden md:flex items-center gap-1 px-1.5 py-0.5 bg-white/[0.06] rounded text-xs ml-auto">
          <Command className="w-3 h-3" />
          <span>K</span>
        </kbd>
      </button>
    );
  }

  return (
    <div 
      className="fixed inset-0 bg-black/50 flex items-start justify-center pt-[20vh] z-[100]"
      onClick={() => setIsOpen(false)}
    >
      <div 
        className="w-full max-w-2xl bg-[#0a0a0a] border border-white/[0.06] rounded-xl shadow-2xl overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3 border-b border-white/[0.06]">
          <Search className="w-5 h-5 text-white/40" />
          <input
            type="text"
            placeholder="Search..."
            className="flex-1 bg-transparent border-none text-white/90 placeholder:text-white/30 focus:outline-none text-lg"
            autoFocus
          />
          <button
            onClick={() => setIsOpen(false)}
            className="px-2 py-1 text-xs text-white/40 hover:text-white/60"
          >
            ESC
          </button>
        </div>
        <div className="p-4 text-center text-white/40">
          Search functionality coming soon...
        </div>
      </div>
    </div>
  );
}
