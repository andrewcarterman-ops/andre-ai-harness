'use client';

import { useEffect, useState } from 'react';
import { useDebounce } from '@/hooks/useDebounce';
import { Doc, DocCategory } from '@/types';
import { 
  FileText, 
  Plus, 
  Search, 
  MoreHorizontal,
  Book,
  Code,
  Lightbulb,
  MessageSquare,
  Archive,
  Folder,
  Clock,
  Edit3,
  Trash2,
  X
} from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import ReactMarkdown from 'react-markdown';

const CATEGORY_ICONS: Record<DocCategory, React.ElementType> = {
  requirements: Book,
  architecture: Code,
  api: Code,
  guide: Book,
  meeting: MessageSquare,
  research: Lightbulb,
  other: FileText,
};

const CATEGORY_COLORS: Record<DocCategory, string> = {
  requirements: 'text-blue-400 bg-blue-500/10',
  architecture: 'text-purple-400 bg-purple-500/10',
  api: 'text-green-400 bg-green-500/10',
  guide: 'text-yellow-400 bg-yellow-500/10',
  meeting: 'text-pink-400 bg-pink-500/10',
  research: 'text-cyan-400 bg-cyan-500/10',
  other: 'text-gray-400 bg-gray-500/10',
};

export default function DocsPage() {
  const [docs, setDocs] = useState<Doc[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const debouncedSearch = useDebounce(searchQuery, 300);
  const [selectedCategory, setSelectedCategory] = useState<DocCategory | 'all'>('all');
  const [selectedDoc, setSelectedDoc] = useState<Doc | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);

  useEffect(() => {
    fetchDocs();
  }, []);

  const fetchDocs = async () => {
    try {
      const res = await fetch('/api/docs');
      if (res.ok) {
        const data = await res.json();
        setDocs(data);
      }
    } catch (error) {
      console.error('Failed to fetch docs:', error);
    }
  };

  const filteredDocs = docs.filter((doc) => {
    const matchesSearch = 
      doc.title.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
      doc.content.toLowerCase().includes(debouncedSearch.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || doc.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const handleCreateDoc = async (e: React.FormEvent) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    
    try {
      const res = await fetch('/api/docs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: formData.get('title'),
          content: formData.get('content'),
          category: formData.get('category'),
          tags: (formData.get('tags') as string).split(',').map((t) => t.trim()).filter(Boolean),
        }),
      });
      
      if (res.ok) {
        await fetchDocs();
        setIsCreateOpen(false);
      }
    } catch (error) {
      console.error('Failed to create doc:', error);
    }
  };

  const handleUpdateDoc = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDoc) return;
    
    const formData = new FormData(e.target as HTMLFormElement);
    
    try {
      const res = await fetch(`/api/docs/${selectedDoc.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: formData.get('title'),
          content: formData.get('content'),
          category: formData.get('category'),
        }),
      });
      
      if (res.ok) {
        await fetchDocs();
        const updated = await res.json();
        setSelectedDoc(updated);
        setIsEditMode(false);
      }
    } catch (error) {
      console.error('Failed to update doc:', error);
    }
  };

  const handleDeleteDoc = async (docId: string) => {
    if (!confirm('Are you sure you want to delete this document?')) return;
    
    try {
      const res = await fetch(`/api/docs/${docId}`, { method: 'DELETE' });
      if (res.ok) {
        await fetchDocs();
        if (selectedDoc?.id === docId) {
          setSelectedDoc(null);
        }
      }
    } catch (error) {
      console.error('Failed to delete doc:', error);
    }
  };

  const categories: { value: DocCategory | 'all'; label: string }[] = [
    { value: 'all', label: 'All Documents' },
    { value: 'requirements', label: 'Requirements' },
    { value: 'architecture', label: 'Architecture' },
    { value: 'api', label: 'API' },
    { value: 'guide', label: 'Guides' },
    { value: 'meeting', label: 'Meetings' },
    { value: 'research', label: 'Research' },
    { value: 'other', label: 'Other' },
  ];

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-white/90 flex items-center gap-3">
            <FileText className="w-6 h-6 text-purple-500" />
            Documents
          </h1>
          <p className="text-white/40 text-sm mt-1">
            Knowledge base and documentation
          </p>
        </div>
        
        <button
          onClick={() => setIsCreateOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Document
        </button>
      </div>

      <div className="flex gap-6 flex-1 overflow-hidden">
        {/* Sidebar */}
        <div className="w-64 flex-shrink-0 space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/40" />
            <input
              type="text"
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 placeholder:text-white/30 focus:outline-none focus:border-purple-500/50"
            />
          </div>

          {/* Categories */}
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-2">
            <div className="text-xs font-medium text-white/40 uppercase px-3 py-2">
              Categories
            </div>
            <div className="space-y-1">
              {categories.map((cat) => {
                const Icon = cat.value === 'all' ? Folder : CATEGORY_ICONS[cat.value as DocCategory] || FileText;
                const count = cat.value === 'all' 
                  ? docs.length 
                  : docs.filter((d) => d.category === cat.value).length;
                
                return (
                  <button
                    key={cat.value}
                    onClick={() => setSelectedCategory(cat.value)}
                    className={cn(
                      'w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm transition-colors',
                      selectedCategory === cat.value
                        ? 'bg-purple-500/20 text-purple-400'
                        : 'text-white/60 hover:bg-white/[0.04]'
                    )}
                  >
                    <div className="flex items-center gap-2">
                      <Icon className="w-4 h-4" />
                      <span>{cat.label}</span>
                    </div>
                    <span className="text-white/30">{count}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Stats */}
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
            <div className="text-sm text-white/40 mb-3">Overview</div>
            <div className="grid grid-cols-2 gap-3">
              <div className="text-center">
                <div className="text-2xl font-semibold text-white/90">{docs.length}</div>
                <div className="text-xs text-white/40">Total</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-semibold text-white/90">
                  {docs.filter((d) => new Date(d.updatedAt) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)).length}
                </div>
                <div className="text-xs text-white/40">This Week</div>
              </div>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 flex gap-6 overflow-hidden">
          {/* Doc List */}
          <div className="w-80 flex-shrink-0 overflow-y-auto">
            <div className="space-y-2">
              {filteredDocs.map((doc) => {
                const Icon = CATEGORY_ICONS[doc.category];
                const colorClass = CATEGORY_COLORS[doc.category];
                
                return (
                  <div
                    key={doc.id}
                    onClick={() => {
                      setSelectedDoc(doc);
                      setIsEditMode(false);
                    }}
                    className={cn(
                      'p-4 rounded-xl border cursor-pointer transition-all',
                      selectedDoc?.id === doc.id
                        ? 'bg-purple-500/10 border-purple-500/30'
                        : 'bg-white/[0.02] border-white/[0.06] hover:border-white/[0.1]'
                    )}
                  >
                    <div className="flex items-start gap-3">
                      <div className={cn('p-2 rounded-lg', colorClass)}>
                        <Icon className="w-4 h-4" />
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <h3 className="font-medium text-white/90 truncate">{doc.title}</h3>
                        <div className="flex items-center gap-2 mt-1 text-xs text-white/40">
                          <span className="capitalize">{doc.category}</span>
                          <span>•</span>
                          <span>{format(new Date(doc.updatedAt), 'MMM dd')}</span>
                        </div>
                        
                        {doc.tags.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-2">
                            {doc.tags.slice(0, 3).map((tag) => (
                              <span
                                key={tag}
                                className="px-2 py-0.5 bg-white/[0.04] rounded text-xs text-white/50"
                              >
                                {tag}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
              
              {filteredDocs.length === 0 && (
                <div className="text-center py-12 text-white/40">
                  <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />
                  <p>No documents found</p>
                </div>
              )}
            </div>
          </div>

          {/* Doc Viewer/Editor */}
          <div className="flex-1 bg-white/[0.02] border border-white/[0.06] rounded-xl overflow-hidden">
            {selectedDoc ? (
              <div className="h-full flex flex-col">
                {/* Toolbar */}
                <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
                  <div className="flex items-center gap-2">
                    {isEditMode ? (
                      <button
                        onClick={() => setIsEditMode(false)}
                        className="px-3 py-1.5 text-sm text-white/60 hover:text-white/90"
                      >
                        Cancel
                      </button>
                    ) : (
                      <button
                        onClick={() => setIsEditMode(true)}
                        className="flex items-center gap-2 px-3 py-1.5 bg-purple-500/20 text-purple-400 rounded-lg hover:bg-purple-500/30 transition-colors"
                      >
                        <Edit3 className="w-4 h-4" />
                        Edit
                      </button>
                    )}
                  </div>
                  
                  <button
                    onClick={() => handleDeleteDoc(selectedDoc.id)}
                    className="p-2 text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-auto p-6">
                  {isEditMode ? (
                    <form onSubmit={handleUpdateDoc} className="space-y-4">
                      <input
                        name="title"
                        defaultValue={selectedDoc.title}
                        className="w-full text-2xl font-semibold bg-transparent border-none text-white/90 focus:outline-none focus:ring-0 placeholder:text-white/30"
                        placeholder="Document title"
                      />
                      
                      <select
                        name="category"
                        defaultValue={selectedDoc.category}
                        className="px-3 py-1.5 bg-white/[0.04] border border-white/[0.06] rounded-lg text-sm text-white/80"
                      >
                        {categories.filter((c) => c.value !== 'all').map((cat) => (
                          <option key={cat.value} value={cat.value}>{cat.label}</option>
                        ))}
                      </select>
                      
                      <textarea
                        name="content"
                        defaultValue={selectedDoc.content}
                        rows={20}
                        className="w-full bg-transparent border-none text-white/80 font-mono text-sm focus:outline-none focus:ring-0 resize-none"
                        placeholder="Write your document in Markdown..."
                      />
                      
                      <div className="flex justify-end">
                        <button
                          type="submit"
                          className="px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg"
                        >
                          Save Changes
                        </button>
                      </div>
                    </form>
                  ) : (
                    <div>
                      <h1 className="text-2xl font-semibold text-white/90 mb-2">{selectedDoc.title}</h1>
                      
                      <div className="flex items-center gap-4 text-sm text-white/40 mb-6">
                        <span className="capitalize px-2 py-1 bg-white/[0.04] rounded">
                          {selectedDoc.category}
                        </span>
                        <span>Updated {format(new Date(selectedDoc.updatedAt), 'MMM dd, yyyy')}</span>
                        <span>Version {selectedDoc.version}</span>
                      </div>
                      
                      <div className="prose prose-invert max-w-none">
                        <ReactMarkdown>{selectedDoc.content || '*No content*'}</ReactMarkdown>
                      </div>
                      
                      {selectedDoc.tags.length > 0 && (
                        <div className="flex flex-wrap gap-2 mt-8 pt-6 border-t border-white/[0.06]">
                          {selectedDoc.tags.map((tag) => (
                            <span
                              key={tag}
                              className="px-3 py-1 bg-white/[0.04] rounded-full text-sm text-white/60"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="flex items-center justify-center h-full text-white/40">
                <div className="text-center">
                  <FileText className="w-16 h-16 mx-auto mb-4 opacity-30" />
                  <p>Select a document to view</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Create Modal */}
      {isCreateOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[#0a0a0a] border border-white/[0.06] rounded-xl p-6 w-full max-w-2xl">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold text-white/90">Create New Document</h2>
              <button
                onClick={() => setIsCreateOpen(false)}
                className="p-1 hover:bg-white/[0.06] rounded"
              >
                <X className="w-5 h-5 text-white/40" />
              </button>
            </div>
            
            <form onSubmit={handleCreateDoc} className="space-y-4">
              <input
                name="title"
                type="text"
                required
                placeholder="Document title"
                className="w-full px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
              />
              
              <div className="flex gap-4">
                <select
                  name="category"
                  required
                  className="px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
                >
                  {categories.filter((c) => c.value !== 'all').map((cat) => (
                    <option key={cat.value} value={cat.value}>{cat.label}</option>
                  ))}
                </select>
                
                <input
                  name="tags"
                  type="text"
                  placeholder="Tags (comma separated)"
                  className="flex-1 px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
                />
              </div>
              
              <textarea
                name="content"
                rows={10}
                placeholder="Write your document in Markdown..."
                className="w-full px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 font-mono text-sm focus:outline-none focus:border-purple-500/50 resize-none"
              />
              
              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="px-4 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/60 hover:bg-white/[0.04]"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg"
                >
                  Create Document
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
