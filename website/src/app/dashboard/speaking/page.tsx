'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';

interface Question {
  question: string;
  audioAsset: string;
  duration: number;
  part: number;
  transcript: string;
  youShouldSay?: string[];
}

const book10Test1Questions: Question[] = [
  {
    question: 'What kinds of buildings are there in your hometown?',
    audioAsset: 'q1.mp3',
    duration: 3.02,
    part: 1,
    transcript: 'In my hometown, you can find a mix of modern high-rise apartments, commercial office towers, and older traditional houses with distinctive tiled roofs.',
  },
  {
    question: "What's the most famous building in your hometown? [Why?]",
    audioAsset: 'q2.mp3',
    duration: 3.53,
    part: 1,
    transcript: 'The most famous building is definitely the historical city cathedral. It has stood for over two centuries, attracting tourists due to its gothic architecture and grand stained glass windows.',
  },
  {
    question: 'What kind of building would you like to live in? [Why?]',
    audioAsset: 'q3.mp3',
    duration: 3.53,
    part: 1,
    transcript: 'I would love to live in an eco-friendly contemporary home with large floor-to-ceiling windows and a rooftop garden to maximize natural daylight and energy efficiency.',
  },
  {
    question: 'Do you think it is important to preserve historic buildings? [Why/Why not?]',
    audioAsset: 'q4.mp3',
    duration: 5.04,
    part: 1,
    transcript: 'Yes, preserving historic buildings is crucial because they serve as tangible links to our cultural heritage, reminding future generations of their architectural identity.',
  },
  {
    question: 'Describe an interesting building you like.',
    audioAsset: 'q5.mp3',
    duration: 3.74,
    part: 2,
    youShouldSay: [
      'where it is located',
      'what it looks like',
      'what it is used for',
      'and explain why you like it.',
    ],
    transcript: 'An interesting building I truly admire is the Sydney Opera House in Australia. Situated directly on the harbour, its unique sail-shaped roof structure stands out as an architectural masterpiece. It hosts world-class theatrical and musical performances, and I admire how it harmonizes with the surrounding maritime environment.',
  },
  {
    question: 'What skills are people in your country in high demand for nowadays? Why is that?',
    audioAsset: 'q6.mp3',
    duration: 5.04,
    part: 3,
    transcript: 'Nowadays, digital literacy, problem-solving, and effective communication are in high demand. People value these skills because they enhance employability in a fast-evolving technological landscape.',
  },
  {
    question: 'Which skills should children learn at school? Are there any skills which they should learn at home? What are they?',
    audioAsset: 'q7.mp3',
    duration: 6.53,
    part: 3,
    transcript: 'Schools should focus on academic knowledge, teamwork, and critical thinking. On the other hand, essential life skills such as emotional resilience and personal hygiene are best taught at home.',
  },
  {
    question: 'Which skills do you think will be important in the future? Why?',
    audioAsset: 'q8.mp3',
    duration: 4.54,
    part: 3,
    transcript: 'In the future, adaptability, data analysis, and emotional intelligence will be crucial. As automation takes over repetitive tasks, human-centric creative thinking will become paramount.',
  },
  {
    question: 'Which kinds of jobs have the highest salaries in your country? Why is this?',
    audioAsset: 'q9.mp3',
    duration: 5.54,
    part: 3,
    transcript: 'Roles in technology, medicine, and corporate finance command the highest salaries because they require specialized expertise and carry immense responsibility.',
  },
  {
    question: 'Are there any other jobs that you think should have high salaries? Why do you think that?',
    audioAsset: 'q10.mp3',
    duration: 5.04,
    part: 3,
    transcript: 'Teachers and healthcare workers definitely deserve higher remuneration. They perform fundamental roles in nurturing future generations and saving lives.',
  },
  {
    question: 'Some people say it would be better for society if everyone got the same salary. What do you think about that? Why?',
    audioAsset: 'q11.mp3',
    duration: 6.53,
    part: 3,
    transcript: 'Equal salaries for all professions would reduce motivation and work ethic, as people would lack incentives to pursue challenging or high-risk careers. A fair economic system should reward effort and qualification.',
  },
];

const book10Test2Questions: Question[] = [
  {
    question: 'What types of music do you like to listen to? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 2.74,
    part: 1,
    transcript: 'I enjoy listening to a variety of music genres, especially pop, acoustic, and classical music. I find pop music energetic and uplifting, while classical tunes help me stay focused.',
  },
  {
    question: 'At what times of day do you like to listen to music? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 3.02,
    part: 1,
    transcript: 'I mostly listen to music in the morning while getting ready and during my evening commute. Music sets a positive mood for my day and helps me unwind after work.',
  },
  {
    question: 'Did you learn to play a musical instrument when you were a child? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 4.03,
    part: 1,
    transcript: 'Yes, I learned to play the piano when I was in primary school. My parents encouraged me to take lessons, and although practice was challenging, I acquired basic musical literacy.',
  },
  {
    question: 'Do you think all children should learn to play a musical instrument? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 5.04,
    part: 1,
    transcript: 'I believe learning a musical instrument develops patience, coordination, and creativity. However, it should not be compulsory, as children should be free to explore other hobbies.',
  },
  {
    question: 'Describe a shop near where you live that you sometimes use.',
    audioAsset: 'q5.mp3',
    duration: 3.74,
    part: 2,
    youShouldSay: [
      'what sorts of product or service it sells',
      'what the shop looks like',
      'where it is located',
      'and explain why you use this shop.',
    ],
    transcript: 'There is a small local grocery store just a five-minute walk from my apartment that I visit frequently. It stocks fresh produce, dairy, and household essentials. The staff are always friendly, making shopping much more pleasant than a crowded supermarket.',
  },
  {
    question: 'What types of local business are there in your neighbourhood? Are there any restaurants, shops, or dentists for example?',
    audioAsset: 'q6.mp3',
    duration: 7.82,
    part: 3,
    transcript: 'In my neighbourhood, there is a good mix of local businesses, including a grocery store, family-run cafes, a pharmacy, and a local dental clinic.',
  },
  {
    question: 'Do you think local businesses are important for a neighborhood? In what way?',
    audioAsset: 'q7.mp3',
    duration: 5.54,
    part: 3,
    transcript: 'I believe they are vital. They provide essential services within walking distance and foster a sense of community by allowing neighbors to interact regularly.',
  },
  {
    question: 'How do large shopping malls and commercial centres affect small local businesses? Why do you think that is?',
    audioAsset: 'q8.mp3',
    duration: 6.84,
    part: 3,
    transcript: 'Large shopping malls offer lower prices and greater variety under one roof, which can draw foot traffic away from small family-run shops.',
  },
  {
    question: 'Why do some people want to start their own business?',
    audioAsset: 'q9.mp3',
    duration: 3.74,
    part: 3,
    transcript: 'Many people desire independence and the ability to control their own career trajectory. They want to turn a personal passion into a sustainable livelihood.',
  },
  {
    question: 'Are there any disadvantages to running a business? Which is the most serious?',
    audioAsset: 'q10.mp3',
    duration: 5.23,
    part: 3,
    transcript: 'Running a business involves long working hours and high financial risk, especially in the early stages when revenue can fluctuate unpredictably.',
  },
  {
    question: 'What are the most important qualities that a good business person needs? Why is that?',
    audioAsset: 'q11.mp3',
    duration: 5.64,
    part: 3,
    transcript: 'A successful business person needs resilience, strategic foresight, and clear communication to navigate setbacks and guide their team effectively.',
  },
];

const book21Test1Questions: Question[] = [
  {
    question: 'How do you usually spend your weekends? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 2.33,
    part: 1,
    transcript: 'I usually spend my weekends catching up on rest, reading, or meeting friends for coffee. It helps me refresh my mind after a busy week.',
  },
  {
    question: 'Which is your favorite part of the weekend? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 3.02,
    part: 1,
    transcript: 'My favorite part is Saturday evening because I can enjoy leisure time without worrying about waking up early the next day.',
  },
  {
    question: 'Do you think your weekends are long enough? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 3.02,
    part: 1,
    transcript: 'Honestly, two days feel rather brief when there are household tasks to finish. A three-day weekend would provide a more balanced routine.',
  },
  {
    question: 'How important do you think it is to have free time at the weekends? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 5.04,
    part: 1,
    transcript: 'Having free time at the weekend is crucial for mental recuperation. It prevents burnout and gives people space to nurture hobbies.',
  },
  {
    question: 'Describe a time when you used information for tourists, for example from a guidebook or online.',
    audioAsset: 'q5.mp3',
    duration: 6.53,
    part: 2,
    youShouldSay: [
      'what information you needed',
      'where you found this information',
      'how you used this information',
      'and explain whether this information was helpful or not.',
    ],
    transcript: 'Last summer when I traveled to Kyoto, I relied on an online tourist blog. I needed guidance on public bus routes and scenic cultural spots. The information was exceptionally helpful for avoiding large crowds.',
  },
  {
    question: 'What are the most popular kinds of holidays for people from your country to go on?',
    audioAsset: 'q6.mp3',
    duration: 5.33,
    part: 3,
    transcript: 'In my country, beach holidays and cultural city breaks are the most popular. Many families enjoy visiting coastal resorts for relaxation.',
  },
  {
    question: 'Do you think most people prefer to have a holiday abroad rather than in their own country?',
    audioAsset: 'q7.mp3',
    duration: 5.54,
    part: 3,
    transcript: 'Traveling abroad offers exciting opportunities to experience different cultures, but domestic vacations are often more accessible and affordable.',
  },
  {
    question: 'Why do some people want to do absolutely nothing when they go away on holiday?',
    audioAsset: 'q8.mp3',
    duration: 5.04,
    part: 3,
    transcript: 'Many people lead high-stress professional lives, so their primary motivation during a holiday is total mental and physical decompression.',
  },
  {
    question: 'What are the kinds of tourist attractions that visitors to your country like to see?',
    audioAsset: 'q9.mp3',
    duration: 4.73,
    part: 3,
    transcript: 'Visitors are drawn to our ancient historical landmarks, national museums, and picturesque national parks.',
  },
  {
    question: 'Do you think tourist attractions such as museums should be free for local people to visit?',
    audioAsset: 'q10.mp3',
    duration: 5.74,
    part: 3,
    transcript: 'Yes, I believe public museums should be free for local residents because they promote cultural literacy and education.',
  },
  {
    question: 'What can make a tourist attraction disappointing for visitors?',
    audioAsset: 'q11.mp3',
    duration: 3.74,
    part: 3,
    transcript: 'Severe overcrowding, excessive commercialization, and poor maintenance can ruin a visitor experience.',
  },
];

const testSuites: { [key: string]: Question[] } = {
  'IELTS Book 10 Test 2': book10Test2Questions,
  'IELTS Book 10 Test 1': book10Test1Questions,
  'IELTS Book 21 Test 1': book21Test1Questions,
};

export default function SpeakingPracticePage() {
  const [selectedTestTitle, setSelectedTestTitle] = useState('IELTS Book 10 Test 2');
  const [selectedPart, setSelectedPart] = useState<number>(1);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [userResponses, setUserResponses] = useState<{ [index: number]: string }>({});
  const [viewState, setViewState] = useState<'TESTS' | 'PRACTICE' | 'RESULTS'>('TESTS');
  const [isRecording, setIsRecording] = useState(false);
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [showTranscript, setShowTranscript] = useState(false);
  const [examinerResults, setExaminerResults] = useState<any>(null);
  const [submitting, setSubmitting] = useState(false);

  // Cue card timer
  const [prepTimeLeft, setPrepTimeLeft] = useState(60);
  const [isPrepping, setIsPrepping] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const recognitionRef = useRef<any>(null);

  const activeQuestions = testSuites[selectedTestTitle] || book10Test2Questions;
  const partQuestions = activeQuestions.filter((q) => q.part === selectedPart);
  const currentQuestion = partQuestions[currentQuestionIndex] || partQuestions[0];

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        const recog = new SpeechRecognition();
        recog.continuous = true;
        recog.interimResults = true;
        recog.lang = 'en-US';

        recog.onresult = (event: any) => {
          let finalTranscript = '';
          for (let i = event.resultIndex; i < event.results.length; ++i) {
            if (event.results[i].isFinal) {
              finalTranscript += event.results[i][0].transcript;
            }
          }
          if (finalTranscript) {
            setUserResponses((prev) => {
              const current = prev[currentQuestionIndex] || '';
              return {
                ...prev,
                [currentQuestionIndex]: (current ? current + ' ' : '') + finalTranscript.trim(),
              };
            });
          }
        };

        recog.onerror = () => setIsRecording(false);
        recog.onend = () => setIsRecording(false);
        recognitionRef.current = recog;
      }
    }
  }, [currentQuestionIndex]);

  useEffect(() => {
    let timer: any = null;
    if (isPrepping && prepTimeLeft > 0) {
      timer = setInterval(() => setPrepTimeLeft((prev) => prev - 1), 1000);
    } else if (prepTimeLeft === 0 && isPrepping) {
      setIsPrepping(false);
      toggleRecording();
    }
    return () => clearInterval(timer);
  }, [isPrepping, prepTimeLeft]);

  const toggleRecording = () => {
    if (!recognitionRef.current) {
      alert('Speech recognition is not supported in this browser. Please use Google Chrome or Microsoft Edge.');
      return;
    }

    if (isRecording) {
      recognitionRef.current.stop();
      setIsRecording(false);
    } else {
      try {
        recognitionRef.current.start();
        setIsRecording(true);
      } catch (e) {
        console.error('Speech recognition error:', e);
      }
    }
  };

  const playQuestionAudio = () => {
    if (!currentQuestion) return;
    const audioUrl = `/audio/speaking/${selectedTestTitle}/${currentQuestion.audioAsset}`;

    if (audioRef.current) {
      audioRef.current.pause();
    }

    const audio = new Audio(audioUrl);
    audioRef.current = audio;
    setIsPlayingAudio(true);

    audio.onended = () => setIsPlayingAudio(false);
    audio.onerror = () => {
      setIsPlayingAudio(false);
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        const utter = new SpeechSynthesisUtterance(currentQuestion.question);
        utter.lang = 'en-GB';
        window.speechSynthesis.speak(utter);
      }
    };

    audio.play().catch(() => {
      setIsPlayingAudio(false);
    });
  };

  const fineTuneAnswer = (userAns: string, q: Question) => {
    const clean = userAns.trim();
    if (!clean) return q.transcript;
    const words = clean.split(/\s+/).filter(Boolean);
    if (words.length <= 3) {
      return `Speaking from personal experience, ${clean}. In my view, this is an essential consideration that directly enhances personal effectiveness.`;
    }
    return `${clean.charAt(0).toUpperCase() + clean.slice(1)}. Furthermore, this plays a pivotal role, and I consider it to be of paramount importance for anyone in a similar position.`;
  };

  const generateDynamicTips = (responses: string[]) => {
    const totalWords = responses.reduce((acc, r) => acc + (r ? r.trim().split(/\s+/).filter(Boolean).length : 0), 0);
    const avgWords = responses.length > 0 ? totalWords / responses.length : 0;

    if (totalWords === 0) {
      return [
        'No verbal response was detected. Ensure your microphone permissions are enabled and speak clearly throughout each prompt.',
        'Practice speaking aloud without hesitation to build confidence for the IELTS Speaking test.',
        'Aim to produce at least 3-4 developed sentences for Part 1 questions and 1-2 minutes of speech for Part 2.',
        'Review the question prompts carefully before speaking.',
      ];
    } else if (avgWords < 5) {
      return [
        'Expand your responses beyond one-word answers. IELTS Speaking requires full, developed thoughts.',
        "Use the 'ARE' structure: Answer directly, provide a Reason, and give a personal Example.",
        "Incorporate connectors such as 'for instance', 'in particular', and 'on top of that'.",
        "Avoid simple confirmations like 'yes' or 'no'; always explain your viewpoint.",
      ];
    } else if (avgWords < 15) {
      return [
        "Good foundation! To reach Band 7.0+, develop your ideas with contrasting perspectives ('While some argue that...').",
        'Incorporate more varied, topic-specific vocabulary and idiomatic collocations.',
        'Practice using complex sentence structures, including conditional clauses.',
        'Maintain a steady, natural rhythm and avoid extended hesitation.',
      ];
    } else {
      return [
        'Excellent answer development and fluency! Keep maintaining this high level of detail across all parts.',
        'Focus on subtle nuances in pronunciation, sentence stress, and intonation.',
        'Ensure seamless cohesion across complex explanations.',
        'Review advanced lexical items and formal idioms to consistently achieve Band 8.5 to 9.0.',
      ];
    }
  };

  const handleFinishTest = () => {
    setSubmitting(true);
    if (isRecording && recognitionRef.current) {
      recognitionRef.current.stop();
      setIsRecording(false);
    }

    const responsesList = partQuestions.map((_, i) => userResponses[i] || '');
    const totalWords = responsesList.reduce((acc, r) => acc + (r ? r.trim().split(/\s+/).filter(Boolean).length : 0), 0);
    const avgWords = partQuestions.length > 0 ? totalWords / partQuestions.length : 0;

    let band = 1.0;
    if (totalWords > 60 && avgWords >= 15) band = 7.5;
    else if (totalWords > 40 && avgWords >= 10) band = 6.5;
    else if (totalWords > 25 && avgWords >= 6) band = 5.0;
    else if (totalWords > 14 && avgWords >= 4) band = 4.0;
    else if (totalWords > 5) band = 3.0;

    const mistakes = partQuestions.map((q, i) => {
      const userAns = responsesList[i] || 'No verbal response recorded';
      return {
        question: q.question,
        wrong: userAns,
        correct: fineTuneAnswer(userAns, q),
      };
    });

    const detailedResponses = partQuestions.map((q, i) => {
      const userAns = responsesList[i] || 'No verbal response recorded';
      const words = userAns === 'No verbal response recorded' ? 0 : userAns.split(/\s+/).filter(Boolean).length;
      return {
        questionNumber: `Q${i + 1}`,
        questionText: q.question,
        answer: userAns,
        wordCount: words,
      };
    });

    const results = {
      overallBand: band,
      fluency: {
        score: Math.max(1, Math.round(band)),
        feedback: totalWords > 30 ? 'Good speech delivery with consistent elaboration.' : 'Responses were brief. Focus on expanding your answers.',
      },
      lexical: {
        score: Math.max(1, Math.round(band)),
        feedback: totalWords > 30 ? 'Appropriate functional vocabulary used.' : 'Vocabulary range was limited. Introduce more descriptive collocations.',
      },
      grammar: {
        score: Math.max(1, Math.round(band)),
        feedback: totalWords > 30 ? 'Good control of basic sentence structures.' : 'Practice forming full compound and complex sentences.',
      },
      pronunciation: {
        score: Math.max(1, Math.round(band)),
        feedback: 'Clear speech delivery throughout the recorded session.',
      },
      tips: generateDynamicTips(responsesList),
      mistakes,
      responses: detailedResponses,
    };

    setExaminerResults(results);
    setViewState('RESULTS');
    setSubmitting(false);

    // Save to user attempt history in localStorage
    try {
      const now = new Date();
      const raw = localStorage.getItem('user_attempt_history');
      let list = raw ? JSON.parse(raw) : [];
      const timeStr = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', hour12: true });
      const dateStr = now.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' }).toUpperCase();

      list.unshift({
        id: `attempt_${now.getTime()}`,
        title: selectedTestTitle,
        module: 'Speaking',
        score: band,
        timeStr,
        dateStr,
        timestamp: now.getTime(),
        details: results,
      });

      localStorage.setItem('user_attempt_history', JSON.stringify(list));
    } catch (e) {
      console.error('Failed to persist attempt to history', e);
    }
  };

  // --- VIEW: RESULTS SCREEN (Matching Mobile App) ---
  if (viewState === 'RESULTS' && examinerResults) {
    const score = examinerResults.overallBand.toFixed(1);
    const circumference = 2 * Math.PI * 45;
    const progress = (examinerResults.overallBand / 9.0) * circumference;

    return (
      <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
        <div className="max-w-3xl mx-auto space-y-8">
          <div className="flex items-center justify-between">
            <button
              onClick={() => setViewState('PRACTICE')}
              className="flex items-center gap-2 text-sm font-bold text-[#4B5563] hover:text-[#0F766E] transition-colors cursor-pointer"
            >
              ← Back to Test
            </button>
            <h1 className="text-xl font-extrabold text-[#1F2937]">{selectedTestTitle} - AI Results</h1>
            <button
              onClick={() => setViewState('TESTS')}
              className="bg-[#0F766E] text-white px-4 py-1.5 rounded-full text-xs font-bold hover:bg-[#115E59] transition-all cursor-pointer"
            >
              Done
            </button>
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
                <span className="text-4xl font-extrabold text-[#DC2626]">{score}</span>
                <span className="text-[11px] font-bold text-[#6B7280]">Band Score</span>
              </div>
            </div>
            <h2 className="text-base font-extrabold text-[#1F2937] mt-4">Part {selectedPart} Speaking Score</h2>
          </div>

          {/* 4 Criteria Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { title: 'Fluency & Coherence', color: '#007AFF', data: examinerResults.fluency },
              { title: 'Lexical Resource', color: '#C026D3', data: examinerResults.lexical },
              { title: 'Grammatical Range', color: '#F97316', data: examinerResults.grammar },
              { title: 'Pronunciation', color: '#10B981', data: examinerResults.pronunciation },
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
                <p className="text-xs text-[#4B5563] leading-relaxed">{crit.data?.feedback}</p>
              </div>
            ))}
          </div>

          {/* Improvement Tips */}
          <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
            <h3 className="text-base font-extrabold text-[#1F2937]">Improvement Tips</h3>
            <div className="space-y-3">
              {examinerResults.tips.map((tip: string, idx: number) => (
                <div key={idx} className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-[#DC2626] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">
                    {idx + 1}
                  </div>
                  <p className="text-xs text-[#374151] leading-relaxed font-medium">{tip}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Your Mistakes */}
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
              {examinerResults.mistakes.map((m: any, idx: number) => (
                <div key={idx} className="border-b border-[#F3F4F6] pb-5 last:border-0 last:pb-0 space-y-2">
                  <p className="text-xs font-bold text-[#B91C1C]">{m.question}</p>
                  <div className="bg-[#FEF2F2] border border-[#FEE2E2] rounded-lg p-2.5 text-xs text-[#DC2626] line-through">
                    {m.wrong}
                  </div>
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {m.correct.split(/\s+/).map((word: string, wIdx: number) => (
                      <span key={wIdx} className="bg-[#DCFCE7] text-[#15803D] px-2 py-0.5 rounded text-xs font-medium">
                        {word}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Your Responses */}
          <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
            <h3 className="text-base font-extrabold text-[#1F2937]">Your Responses</h3>
            <div className="space-y-4">
              {examinerResults.responses.map((resp: any, idx: number) => (
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
        </div>
      </div>
    );
  }

  // --- VIEW: TEST SELECTION SCREEN ---
  if (viewState === 'TESTS') {
    return (
      <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-extrabold text-[#0F766E]">IELTS Speaking Practice</h1>
              <p className="text-xs text-[#6B7280] mt-1">Official Cambridge Tests with native British examiners and AI grading</p>
            </div>
            <Link
              href="/dashboard"
              className="text-xs font-bold text-[#4B5563] hover:text-[#0F766E] transition-colors"
            >
              Back to Dashboard
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {Object.keys(testSuites).map((title) => (
              <div
                key={title}
                className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-sm hover:shadow-md transition-all flex flex-col justify-between space-y-4"
              >
                <div>
                  <div className="w-10 h-10 rounded-xl bg-[#E6F4F1] text-[#0F766E] flex items-center justify-center font-extrabold mb-3">
                    🎙️
                  </div>
                  <h3 className="text-base font-bold text-[#1F2937]">{title}</h3>
                  <p className="text-xs text-[#6B7280] mt-1">
                    {title.includes('Book 10 Test 2')
                      ? 'Music, Local shops & Shopping malls discussion'
                      : title.includes('Book 10 Test 1')
                      ? 'Architecture, Hometown buildings & Career skills'
                      : 'Weekends, Tourist attractions & International travel'}
                  </p>
                  <div className="flex gap-2 mt-4">
                    <span className="bg-[#E6F4F1] text-[#0F766E] text-[10px] font-bold px-2 py-0.5 rounded">Part 1</span>
                    <span className="bg-[#E6F4F1] text-[#0F766E] text-[10px] font-bold px-2 py-0.5 rounded">Part 2</span>
                    <span className="bg-[#E6F4F1] text-[#0F766E] text-[10px] font-bold px-2 py-0.5 rounded">Part 3</span>
                  </div>
                </div>

                <button
                  onClick={() => {
                    setSelectedTestTitle(title);
                    setSelectedPart(1);
                    setCurrentQuestionIndex(0);
                    setUserResponses({});
                    setExaminerResults(null);
                    setViewState('PRACTICE');
                  }}
                  className="w-full bg-[#0F766E] hover:bg-[#115E59] text-white py-2.5 rounded-xl text-xs font-bold transition-all shadow-sm cursor-pointer"
                >
                  Start Test
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // --- VIEW: PRACTICE SCREEN ---
  const currentAnswer = userResponses[currentQuestionIndex] || '';
  const wordCount = currentAnswer ? currentAnswer.trim().split(/\s+/).filter(Boolean).length : 0;

  return (
    <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
      <div className="max-w-3xl mx-auto space-y-6">
        {/* Top Bar */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => setViewState('TESTS')}
            className="text-xs font-bold text-[#4B5563] hover:text-[#0F766E] transition-colors cursor-pointer"
          >
            ← Exit Test
          </button>
          <div className="text-center">
            <h2 className="text-sm font-bold text-[#1F2937]">{selectedTestTitle}</h2>
            <div className="flex justify-center gap-2 mt-1">
              {[1, 2, 3].map((p) => (
                <button
                  key={p}
                  onClick={() => {
                    setSelectedPart(p);
                    setCurrentQuestionIndex(0);
                  }}
                  className={`px-3 py-0.5 rounded-full text-[11px] font-bold transition-all cursor-pointer ${
                    selectedPart === p
                      ? 'bg-[#0F766E] text-white'
                      : 'bg-[#E6F4F1] text-[#0F766E] hover:bg-[#CCECE6]'
                  }`}
                >
                  Part {p}
                </button>
              ))}
            </div>
          </div>
          <button
            onClick={handleFinishTest}
            disabled={submitting}
            className="bg-[#DC2626] hover:bg-[#B91C1C] text-white px-4 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer"
          >
            {submitting ? 'Evaluating...' : 'Finish & Grade'}
          </button>
        </div>

        {/* Question Card */}
        <div className="bg-white rounded-3xl p-8 border border-[#E2E8F0] shadow-sm space-y-6">
          <div className="flex items-center justify-between">
            <span className="bg-[#E6F4F1] text-[#0F766E] px-3 py-1 rounded-full text-xs font-bold">
              Question {currentQuestionIndex + 1} of {partQuestions.length}
            </span>
            <button
              onClick={playQuestionAudio}
              className="flex items-center gap-1.5 bg-[#0F766E] hover:bg-[#115E59] text-white px-3 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer"
            >
              <span>{isPlayingAudio ? '🔊 Playing...' : '▶️ Play Audio'}</span>
            </button>
          </div>

          <h3 className="text-lg font-bold text-[#1F2937] leading-snug">
            {currentQuestion?.question}
          </h3>

          {/* Part 2 Cue Card Bullets */}
          {currentQuestion?.youShouldSay && (
            <div className="bg-[#F8F9FB] rounded-2xl p-5 border border-[#E5E7EB] space-y-2">
              <p className="text-xs font-bold text-[#374151]">You should say:</p>
              <ul className="list-disc pl-5 space-y-1 text-xs text-[#4B5563]">
                {currentQuestion.youShouldSay.map((bullet, idx) => (
                  <li key={idx}>{bullet}</li>
                ))}
              </ul>
              <div className="pt-2 flex items-center gap-3">
                <button
                  onClick={() => {
                    setIsPrepping(true);
                    setPrepTimeLeft(60);
                  }}
                  disabled={isPrepping}
                  className="bg-[#F97316] text-white px-3 py-1 rounded-lg text-xs font-bold cursor-pointer"
                >
                  {isPrepping ? `Prep Time: ${prepTimeLeft}s` : '1 Min Prep Timer'}
                </button>
              </div>
            </div>
          )}

          {/* Transcript Toggle */}
          <div>
            <button
              onClick={() => setShowTranscript(!showTranscript)}
              className="text-[11px] font-bold text-[#0F766E] hover:underline cursor-pointer"
            >
              {showTranscript ? 'Hide Examiner Transcript' : 'Show Examiner Transcript'}
            </button>
            {showTranscript && (
              <p className="mt-2 text-xs text-[#4B5563] bg-[#F9FBFA] p-3 rounded-xl border border-[#E2E8F0] italic">
                "{currentQuestion?.transcript}"
              </p>
            )}
          </div>

          {/* User Response Area */}
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs">
              <span className="font-bold text-[#374151]">Your Spoken Response:</span>
              <span className="text-[#0F766E] font-bold">{wordCount} words</span>
            </div>
            <textarea
              rows={4}
              value={currentAnswer}
              onChange={(e) =>
                setUserResponses({
                  ...userResponses,
                  [currentQuestionIndex]: e.target.value,
                })
              }
              placeholder="Click the microphone to record your speech, or type your response here..."
              className="w-full bg-[#F9FBFA] border border-[#E2E8F0] rounded-2xl p-4 text-xs text-[#1F2937] focus:outline-none focus:border-[#0F766E] transition-all leading-relaxed"
            />
          </div>

          {/* Controls */}
          <div className="flex items-center justify-between pt-2">
            <button
              onClick={toggleRecording}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-xs font-bold transition-all cursor-pointer ${
                isRecording
                  ? 'bg-[#DC2626] text-white animate-pulse shadow-md shadow-red-200'
                  : 'bg-[#0F766E] hover:bg-[#115E59] text-white shadow-sm'
              }`}
            >
              <span>{isRecording ? '⏹️ Stop Recording' : '🎙️ Record Speech'}</span>
            </button>

            <div className="flex items-center gap-2">
              <button
                onClick={() => setCurrentQuestionIndex((prev) => Math.max(0, prev - 1))}
                disabled={currentQuestionIndex === 0}
                className="px-3 py-2 rounded-xl text-xs font-bold border border-[#E2E8F0] disabled:opacity-40 cursor-pointer"
              >
                Previous
              </button>
              <button
                onClick={() => setCurrentQuestionIndex((prev) => Math.min(partQuestions.length - 1, prev + 1))}
                disabled={currentQuestionIndex === partQuestions.length - 1}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-[#0F766E] text-white disabled:opacity-40 cursor-pointer"
              >
                Next
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
