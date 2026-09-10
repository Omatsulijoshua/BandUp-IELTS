'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function HistoryDashboard() {
  const [loading, setLoading] = useState(true);
  const [historyItems, setHistoryItems] = useState<any[]>([]);
  const [selectedFilter, setSelectedFilter] = useState<string>('All');
  const [selectedAttempt, setSelectedAttempt] = useState<any | null>(null);

  useEffect(() => {
    loadHistory();
  }, []);

  const loadHistory = async () => {
    setLoading(true);
    let items: any[] = [];

    // 1. Load from localStorage (strictly user-generated results)
    try {
      if (typeof window !== 'undefined') {
        const raw = localStorage.getItem('user_attempt_history');
        if (raw) {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            // Purge dummy seeds if present
            items = parsed.filter(
              (it) =>
                it.id !== 'b10t2_speaking_1' &&
                it.id !== 'b10t1_speaking_1' &&
                it.id !== 'b21t1_speaking_1'
            );
            localStorage.setItem('user_attempt_history', JSON.stringify(items));
          }
        }
      }
    } catch (e) {
      console.error('Failed to parse local history', e);
    }

    // 2. Fetch from backend API if available
    try {
      const data = await api.request<any>('/analytics/history');
      if (data) {
        const existingIds = new Set(items.map((i) => i.id));
        const checkList = (list: any[], moduleName: string) => {
          if (!list) return;
          for (const item of list) {
            const id = item.id?.toString() || '';
            if (id && !existingIds.has(id)) {
              existingIds.add(id);
              const createdAt = item.createdAt ? new Date(item.createdAt) : new Date();
              items.push({
                id,
                title: item.prompt?.title || item.prompt?.topic || `IELTS ${moduleName} Practice`,
                module: moduleName,
                score: item.bandScoreEstimate || 5.0,
                timeStr: createdAt.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', hour12: true }),
                dateStr: createdAt.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' }).toUpperCase(),
                timestamp: createdAt.getTime(),
              });
            }
          }
        };

        checkList(data.practiceMode?.speaking, 'Speaking');
        checkList(data.practiceMode?.writing, 'Writing');
        checkList(data.examMode?.speaking, 'Speaking');
        checkList(data.examMode?.writing, 'Writing');
      }
    } catch (e) {
      // Backend history optional
    }

    // Sort by timestamp desc
    items.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
    setHistoryItems(items);
    setLoading(false);
  };

  const filteredItems =
    selectedFilter === 'All'
      ? historyItems
      : historyItems.filter((item) => (item.module || '').toLowerCase() === selectedFilter.toLowerCase());

  const totalTests = historyItems.length;
  const avgScore =
    totalTests > 0
      ? (historyItems.reduce((acc, it) => acc + (Number(it.score) || 0), 0) / totalTests).toFixed(1)
      : '0.0';
  const bestScore =
    totalTests > 0
      ? Math.max(...historyItems.map((it) => Number(it.score) || 0)).toFixed(1)
      : '0.0';

  // --- DETAIL VIEW ---
  if (selectedAttempt) {
    const details = selectedAttempt.details || {};
    const scoreVal = Number(selectedAttempt.score || 0).toFixed(1);
    const circumference = 2 * Math.PI * 45;
    const progress = (Number(selectedAttempt.score || 0) / 9.0) * circumference;

    return (
      <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
        <div className="max-w-3xl mx-auto space-y-6">
          <div className="flex items-center justify-between">
            <button
              onClick={() => setSelectedAttempt(null)}
              className="flex items-center gap-1.5 text-xs font-bold text-[#4B5563] hover:text-[#0F766E] transition-colors cursor-pointer"
            >
              ← Back to History
            </button>
            <h1 className="text-sm font-extrabold text-[#1F2937]">{selectedAttempt.title}</h1>
            <span className="text-[11px] text-[#6B7280] font-medium">{selectedAttempt.timeStr}</span>
          </div>

          {/* Score Gauge */}
          <div className="bg-white rounded-3xl p-8 border border-[#E2E8F0] shadow-sm flex flex-col items-center justify-center text-center">
            <div className="relative w-36 h-36 flex items-center justify-center">
              <svg className="w-full h-full transform -rotate-90">
                <circle cx="72" cy="72" r="45" stroke="#E5E7EB" strokeWidth="10" fill="transparent" />
                <circle
                  cx="72"
                  cy="72"
                  r="45"
                  stroke="#DC2626"
                  strokeWidth="10"
                  fill="transparent"
                  strokeDasharray={circumference}
                  strokeDashoffset={circumference - progress}
                  strokeLinecap="round"
                />
              </svg>
              <div className="absolute flex flex-col items-center">
                <span className="text-4xl font-extrabold text-[#DC2626]">{scoreVal}</span>
                <span className="text-[11px] font-bold text-[#6B7280]">{selectedAttempt.module} Band</span>
              </div>
            </div>
          </div>

          {/* Criteria Cards (if available) */}
          {(details.fluency || details.taskResponse) && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {[
                { title: details.fluency ? 'Fluency & Coherence' : 'Task Achievement', color: '#007AFF', data: details.fluency || details.taskResponse },
                { title: details.lexical ? 'Lexical Resource' : 'Coherence & Cohesion', color: '#C026D3', data: details.lexical || details.coherence },
                { title: details.grammar ? 'Grammatical Range' : 'Lexical Resource', color: '#F97316', data: details.grammar || details.lexicalResource },
                { title: details.pronunciation ? 'Pronunciation' : 'Grammatical Range', color: '#10B981', data: details.pronunciation || details.grammaticalRange },
              ].map((crit, idx) => (
                <div key={idx} className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: crit.color }} />
                      <span className="text-xs font-bold text-[#1F2937]">{crit.title}</span>
                    </div>
                    <span className="bg-[#FEE2E2] text-[#DC2626] px-2 py-0.5 rounded text-xs font-extrabold">
                      {crit.data?.score ?? 1}
                    </span>
                  </div>
                  <p className="text-xs text-[#4B5563] leading-relaxed">{crit.data?.feedback || 'Good overall performance.'}</p>
                </div>
              ))}
            </div>
          )}

          {/* Improvement Tips */}
          {details.tips && details.tips.length > 0 && (
            <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
              <h3 className="text-base font-extrabold text-[#1F2937]">Improvement Tips</h3>
              <div className="space-y-3">
                {details.tips.map((tip: string, idx: number) => (
                  <div key={idx} className="flex items-start gap-3">
                    <div className="w-5 h-5 rounded-full bg-[#DC2626] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">
                      {idx + 1}
                    </div>
                    <p className="text-xs text-[#374151] leading-relaxed font-medium">{tip}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Your Mistakes */}
          {details.mistakes && details.mistakes.length > 0 && (
            <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-[#F59E0B] font-bold">⚠️</span>
                  <h3 className="text-base font-extrabold text-[#1F2937]">Your Mistakes</h3>
                </div>
                <div className="flex items-center gap-4 text-xs">
                  <span className="text-[#DC2626] line-through font-semibold">ab Wrong</span>
                  <span className="text-[#10B981] font-semibold">ab Correct</span>
                </div>
              </div>
              <div className="space-y-6">
                {details.mistakes.map((m: any, idx: number) => (
                  <div key={idx} className="border-b border-[#F3F4F6] pb-5 last:border-0 last:pb-0 space-y-2">
                    <p className="text-xs font-bold text-[#B91C1C]">{m.question}</p>
                    <div className="bg-[#FEF2F2] border border-[#FEE2E2] rounded-lg p-2.5 text-xs text-[#DC2626] line-through">
                      {m.wrong}
                    </div>
                    <div className="flex flex-wrap gap-1.5 pt-1">
                      {(m.correct || '').split(/\s+/).map((word: string, wIdx: number) => (
                        <span key={wIdx} className="bg-[#DCFCE7] text-[#15803D] px-2 py-0.5 rounded text-xs font-medium">
                          {word}
                        </span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Your Responses */}
          {details.responses && details.responses.length > 0 && (
            <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
              <h3 className="text-base font-extrabold text-[#1F2937]">Your Responses</h3>
              <div className="space-y-4">
                {details.responses.map((resp: any, idx: number) => (
                  <div key={idx} className="border-b border-[#F3F4F6] pb-4 last:border-0 last:pb-0 space-y-1.5">
                    <div className="flex items-center justify-between">
                      <span className="bg-[#DC2626] text-white px-2 py-0.5 rounded text-[10px] font-bold">
                        {resp.questionNumber}
                      </span>
                      <span className="text-[11px] font-bold text-[#DC2626]">{resp.wordCount} words</span>
                    </div>
                    <p className="text-xs font-bold text-[#374151]">{resp.questionText}</p>
                    <p className="text-xs text-[#4B5563] italic">"{resp.answer}"</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  // --- MAIN LIST VIEW ---
  return (
    <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-extrabold text-[#0F766E]">Practice & Test History</h1>
            <p className="text-xs text-[#6B7280] mt-1">Review your genuine performance analytics and previous test scores</p>
          </div>
          <Link
            href="/dashboard"
            className="text-xs font-bold text-[#4B5563] hover:text-[#0F766E] transition-colors"
          >
            Back to Dashboard
          </Link>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm text-center">
            <p className="text-2xl font-extrabold text-[#1F2937]">{avgScore}</p>
            <p className="text-xs text-[#6B7280] font-semibold mt-1">Avg Score</p>
          </div>
          <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm text-center">
            <p className="text-2xl font-extrabold text-[#0F766E]">{bestScore}</p>
            <p className="text-xs text-[#6B7280] font-semibold mt-1">Best Score</p>
          </div>
          <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm text-center">
            <p className="text-2xl font-extrabold text-[#F97316]">{totalTests}</p>
            <p className="text-xs text-[#6B7280] font-semibold mt-1">Total Tests</p>
          </div>
        </div>

        {/* Filter Chips */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          {['All', 'Speaking', 'Writing', 'Reading', 'Listening'].map((f) => (
            <button
              key={f}
              onClick={() => setSelectedFilter(f)}
              className={`px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
                selectedFilter === f
                  ? 'bg-[#0F766E] text-white shadow-sm'
                  : 'bg-white border border-[#E2E8F0] text-[#4B5563] hover:bg-[#F3F4F6]'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        {/* List of Attempt Cards */}
        {loading ? (
          <div className="text-center py-16 text-xs text-[#6B7280]">Loading your test history...</div>
        ) : filteredItems.length === 0 ? (
          <div className="bg-white rounded-3xl p-12 border border-[#E2E8F0] shadow-sm text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-[#E6F4F1] text-[#0F766E] flex items-center justify-center mx-auto text-2xl">
              📝
            </div>
            <h3 className="text-base font-bold text-[#1F2937]">No {selectedFilter !== 'All' ? selectedFilter : ''} History Yet</h3>
            <p className="text-xs text-[#6B7280] max-w-sm mx-auto">
              Complete a practice session or mock test to see your official band score and detailed AI evaluation here.
            </p>
            <div className="pt-2">
              <Link
                href="/dashboard/speaking"
                className="bg-[#0F766E] hover:bg-[#115E59] text-white px-5 py-2.5 rounded-full text-xs font-bold transition-all inline-block shadow-sm"
              >
                Start Practice Test
              </Link>
            </div>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                onClick={() => setSelectedAttempt(item)}
                className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm hover:shadow-md transition-all flex items-center justify-between cursor-pointer group"
              >
                <div className="flex items-center gap-4">
                  <div className="w-11 h-11 rounded-2xl bg-[#E6F4F1] text-[#0F766E] flex items-center justify-center font-bold text-base shrink-0">
                    {item.module === 'Speaking'
                      ? '🎙️'
                      : item.module === 'Writing'
                      ? '✍️'
                      : item.module === 'Reading'
                      ? '📖'
                      : '🎧'}
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-[#1F2937] group-hover:text-[#0F766E] transition-colors">
                      {item.title}
                    </h4>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[11px] font-bold text-[#0F766E]">{item.module}</span>
                      <span className="text-[11px] text-[#9CA3AF]">•</span>
                      <span className="text-[11px] text-[#9CA3AF]">{item.timeStr || item.dateStr}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span className="text-lg font-extrabold text-[#DC2626]">
                    {Number(item.score || 0).toFixed(1)}
                  </span>
                  <span className="text-[#9CA3AF] text-sm group-hover:translate-x-0.5 transition-transform">
                    →
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
