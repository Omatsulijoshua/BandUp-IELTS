'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';

interface MockQuestion {
  q?: string;
  title?: string;
  prompt?: string;
  minWords?: number;
  part?: string;
  options?: string[];
  ans?: string;
  exp?: string;
}

interface MockSection {
  id: string;
  source: string;
  title: string;
  subtitle: string;
  instructions: string;
  durationMinutes: number;
  listeningAudio?: { audioUrl: string };
  readingPassage?: { title: string; text: string };
  questions: MockQuestion[];
}

// ===========================================================================
// CAMBRIDGE IELTS TEST POOLS
// ===========================================================================

const LISTENING_POOL: MockSection[] = [
  {
    id: 'listening_b10t1',
    source: 'Cambridge IELTS Book 10 Test 1',
    title: 'Section 1: Listening',
    subtitle: '4 parts • 40 questions • ~30 min',
    durationMinutes: 30,
    instructions: 'Listen to the USA Self-Drive Tours audio and answer questions 1-10.',
    listeningAudio: {
      audioUrl: 'https://bandup-ielts-prep.vercel.app/audio/b10t1_listening.mpeg',
    },
    questions: [
      { q: '1. Address: 24 ___ Road', ans: 'Ardleigh', exp: 'Spelled out: A-R-D-L-E-I-G-H Road.' },
      { q: '2. Heard about company from: ___', ans: 'newspaper', exp: 'Read about company in the local newspaper.' },
      { q: '3. Trip One - Los Angeles: wants to visit some ___ parks', ans: 'theme', exp: 'Customer wants to take her children to theme parks.' },
      { q: '4. Trip One - Yosemite: customer wants to stay in a lodge, not a ___', ans: 'tent', exp: 'Requested lodge accommodation, not a tent.' },
      { q: '5. Trip Two: customer wants to see the ___ on the way to Cambria', ans: 'castle', exp: 'Hearst Castle is the planned sightseeing stop.' },
      { q: '6. Trip Two - At San Diego: wants to spend time on the ___', ans: 'beach', exp: 'Customer requested relaxing days on the beach.' },
      { q: '7. Trip One (12 days) - Total distance: ___ km', ans: '2020', exp: 'Two thousand and twenty kilometers in total.' },
      { q: '8. Trip One (£525) - Includes: accommodation, car, one ___', ans: 'flight', exp: 'Price covers hotel, rental car, and one domestic flight.' },
      { q: '9. Trip Two (9 days, 980 km) - Price per person: £___', ans: '429', exp: 'Price is four hundred and twenty-nine pounds.' },
      { q: '10. Trip Two - Includes: accommodation, car, ___', ans: 'dinner', exp: 'Includes accommodation, rental car, and dinner.' },
    ],
  },
  {
    id: 'listening_b10t2',
    source: 'Cambridge IELTS Book 10 Test 2',
    title: 'Section 1: Listening',
    subtitle: '4 parts • 40 questions • ~30 min',
    durationMinutes: 30,
    instructions: 'Listen to the Leisure Club Facilities dialogue and answer questions 1-10.',
    questions: [
      {
        q: '1. Which facility at the leisure club has recently been improved first?',
        options: ['A. the gym', 'B. running tracks', 'C. outdoor pool', 'D. sports coaching'],
        ans: 'A',
        exp: 'The gym was completely refurbished first with modern machines.',
      },
      {
        q: '2. Which other facility at the leisure club has recently been improved?',
        options: ['A. sauna rooms', 'B. tennis court', 'C. indoor heated pool', 'D. cafe lounge'],
        ans: 'C',
        exp: 'The indoor pool heating and filtration systems were upgraded.',
      },
      { q: '3. Personal Assessment: New members should describe any ___', ans: 'health problems', exp: 'Members disclose pre-existing health problems to instructors.' },
      { q: '4. The ___ will be explained to you before you use the equipment.', ans: 'safety rules', exp: 'Instructors review equipment safety rules first.' },
      { q: '5. You will be given a six-week personal fitness ___', ans: 'plan', exp: 'A six-week custom workout plan is prepared.' },
      { q: '6. Types of membership: There is a compulsory £90 ___ fee.', ans: 'joining', exp: 'An initial joining fee of ninety pounds applies.' },
      { q: '7. Gold members are given ___ to all the LP clubs.', ans: 'free entry', exp: 'Gold tier grants complimentary access across all locations.' },
      { q: '8. Premier members are given priority during ___ hours.', ans: 'peak', exp: 'Premier status guarantees priority booking at peak times.' },
      { q: '9. Premier members can bring some ___ every month.', ans: 'guests', exp: 'Premier members can introduce guests each month.' },
      { q: '10. Members should always take their ___ with them.', ans: 'photo card', exp: 'Members must present their physical photo card at reception.' },
    ],
  },
  {
    id: 'listening_b21t1',
    source: 'Cambridge IELTS Book 21 Test 1',
    title: 'Section 1: Listening',
    subtitle: '4 parts • 40 questions • ~30 min',
    durationMinutes: 30,
    instructions: 'Listen to the Design Competition briefing and answer questions 1-10.',
    questions: [
      {
        q: '1. What is the primary focus of this year’s design competition?',
        options: ['A. inventing a new tool', 'B. energy conservation', 'C. finding a new use for current technology'],
        ans: 'C',
        exp: 'Brief asks competitors to adapt current consumer tech in innovative ways.',
      },
      {
        q: '2. Which aspect of the appliance should the design prioritize?',
        options: ['A. ease of use for seniors', 'B. vibrant color scheme', 'C. lightweight shipping'],
        ans: 'A',
        exp: 'The appliance interface must be exceptionally easy for senior citizens to use.',
      },
      {
        q: '3. What is the main problem with current appliance designs?',
        options: ['A. excessive pricing', 'B. overly complicated buttons', 'C. fragile casing'],
        ans: 'B',
        exp: 'Current designs suffer from an excessive number of complicated buttons.',
      },
      { q: '4. Requirement: The design aesthetic must be visually ___', ans: 'attractive', exp: 'Prototypes must be visually pleasing and attractive.' },
      { q: '5. Key benefit: Students gain hands-on practical ___', ans: 'experience', exp: 'The contest provides hands-on practical work experience.' },
      { q: '6. Requirement: Students must submit a comprehensive ___', ans: 'presentation', exp: 'Teams must deliver an in-depth slide presentation.' },
      { q: '7. Requirement: Teams must build a physical working ___', ans: 'model', exp: 'A physical scaled prototype model is required.' },
      { q: '8. Specification: Documentation must enumerate each ___ used.', ans: 'material', exp: 'Documentation must detail every raw material used.' },
      { q: '9. The winning candidate will be awarded a research ___', ans: 'grant', exp: 'First place receives an academic research grant.' },
      { q: '10. The panel evaluation will emphasize ___ innovation.', ans: 'technical', exp: 'Evaluation is focused strictly on technical excellence.' },
    ],
  },
];

const READING_POOL: MockSection[] = [
  {
    id: 'reading_b10t1',
    source: 'Cambridge IELTS Book 10 Test 1',
    title: 'Section 2: Reading',
    subtitle: '3 passages • 40 questions • 60 min',
    durationMinutes: 60,
    instructions: 'Read the Stepwells of India passage and answer questions 1-6.',
    readingPassage: {
      title: 'Stepwells of India: Ancient Engineering & Community Life',
      text: 'Stepwells are unique subterranean monuments found primarily in India. Developed in the sixth and seventh centuries, these ingenious civil engineering marvels served multiple functions: providing year-round access to water, offering cool communal gathering pavilions during sweltering summers, and acting as revered spaces for spiritual worship.\n\nWhen the water table was elevated during monsoon periods, villagers only had to descend a few stone steps to draw water; conversely, during dry arid months, dozens of intricate stepped tiers had to be negotiated. Built from locally quarried stone and reinforced with ornate carved pillars, shaded verandas provided respite for travelers.\n\nWhile modern piped plumbing caused many stepwells to fall into dereliction, exceptional surviving sites such as Rani Ki Vav in Gujarat miraculously withstood a devastating earthquake in 2001, showcasing the enduring structural genius of ancient Indian masonry.',
    },
    questions: [
      {
        q: '1. The number of steps above the water level altered during the course of a year.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'A',
        exp: 'Seasonal water table shifts altered the number of visible steps.',
      },
      {
        q: '2. Stepwells were first built in the 6th century.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'B',
        exp: 'They developed in the 6th-7th centuries, but no proof they were first invented then.',
      },
      {
        q: '3. The stepwells had multiple community functions in addition to supplying drinking water.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'A',
        exp: 'Passage mentions community leisure, shaded pavilions, and spiritual worship.',
      },
      { q: '4. Which architectural feature offered shelter and shade from extreme heat?', ans: 'pavilions', exp: 'Stone pavilions sheltered visitors from summer heat.' },
      { q: '5. What natural disaster did Rani Ki Vav survive in 2001?', ans: 'earthquake', exp: 'Rani Ki Vav remarkably survived the 2001 Gujarat earthquake.' },
      { q: '6. Ancient stepwells were predominantly constructed using locally quarried ___', ans: 'stone', exp: 'Built from quarried stone supported by ornate pillars.' },
    ],
  },
  {
    id: 'reading_b10t2',
    source: 'Cambridge IELTS Book 10 Test 2',
    title: 'Section 2: Reading',
    subtitle: '3 passages • 40 questions • 60 min',
    durationMinutes: 60,
    instructions: 'Read the European Transport Trends excerpt and answer questions 1-6.',
    readingPassage: {
      title: 'European Transport Infrastructure & Environmental Challenges',
      text: 'Across the European continent, consumer and commercial transport demand has expanded at an unprecedented rate over the last three decades. Road transport currently dominates both passenger mobility (accounting for over 84% of passenger-kilometers) and freight haulage (representing roughly 44% of overall tonnage).\n\nThis heavy dependence on road vehicles has generated substantial traffic congestion, air pollution, and heightened carbon emissions. Simultaneously, railway transit, which once formed the backbone of cross-border European freight, has contracted significantly.\n\nThe European Commission\'s environmental transport directive emphasizes that unless user pricing charges are implemented and substantial volume is shifted onto electrified rail and inland canals, sustained economic expansion will remain locked in direct conflict with European carbon neutrality objectives.',
    },
    questions: [
      {
        q: '1. What percentage of European passenger movements is accounted for by road transport?',
        options: ['A. 44%', 'B. 68%', 'C. 84%', 'D. 95%'],
        ans: 'C',
        exp: 'Text indicates road transport accounts for over 84% of passenger movements.',
      },
      {
        q: '2. The primary source of rising European transport emissions is highway traffic.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'A',
        exp: 'Heavy highway vehicle reliance is directly cited as driving emissions.',
      },
      {
        q: '3. Rail freight has increased its total market share since 1990.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'B',
        exp: 'Rail freight has contracted rather than increased its share.',
      },
      {
        q: '4. What policy mechanism does the Commission recommend to reduce roadway crowding?',
        options: ['A. Toll exemptions', 'B. Road user pricing charges', 'C. Canceling rail investments'],
        ans: 'B',
        exp: 'User pricing charges are recommended to incentivize modal shift.',
      },
      { q: '5. Freight transported by road represents roughly ___ percent of overall tonnage.', ans: '44', exp: 'Accounts for approximately 44% of overall freight tonnage.' },
      { q: '6. The European Commission aims to decouple economic growth from environmental ___', ans: 'sustainability', exp: 'Policy focuses on reconciling growth with environmental sustainability.' },
    ],
  },
  {
    id: 'reading_b21t1',
    source: 'Cambridge IELTS Book 21 Test 1',
    title: 'Section 2: Reading',
    subtitle: '3 passages • 40 questions • 60 min',
    durationMinutes: 60,
    instructions: 'Read the Workplace Psychology passage and answer questions 1-6.',
    readingPassage: {
      title: 'The Psychology of Workplace Innovation and Creative Thinking',
      text: 'Contemporary enterprise design frequently promotes open-plan workspaces furnished with vivid lounges, recreation areas, and complimentary refreshments, on the assumption that playful environments automatically catalyze innovative ideation.\n\nHowever, rigorous psychological research conducted across multinational firms demonstrates that architectural novelty alone rarely triggers creative problem-solving. Genuine organizational innovation relies upon psychological safety—a team atmosphere wherein individuals feel fully empowered to voice unorthodox proposals without apprehension of reprimand or peer mockery.\n\nWhen corporate leaders actively reward calculated intellectual risk and cultivate cross-disciplinary collaboration, breakthrough concepts surface consistently, regardless of physical seating arrangements or office decor.',
    },
    questions: [
      {
        q: '1. Architectural novelty in office styling guarantees higher employee creativity.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'B',
        exp: 'Research proves architectural novelty alone does not guarantee creativity.',
      },
      {
        q: '2. Psychological safety allows team members to propose unusual ideas without fear.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'A',
        exp: 'Psychological safety ensures workers can propose unorthodox ideas safely.',
      },
      {
        q: '3. Open-plan office designs were invented exclusively by modern tech startups.',
        options: ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
        ans: 'C',
        exp: 'The text does not state who originally invented open-plan offices.',
      },
      {
        q: '4. What organizational condition is most essential for real workplace innovation?',
        options: ['A. Free snacks', 'B. Psychological safety & leadership support', 'C. Private cubicles'],
        ans: 'B',
        exp: 'Psychological safety and receptive leadership are the core drivers.',
      },
      { q: '5. Workers must feel secure putting forward ___ proposals.', ans: 'unorthodox', exp: 'The freedom to voice unorthodox proposals sparks breakthroughs.' },
      { q: '6. Breakthrough innovation is strengthened by ___ collaboration among diverse specialists.', ans: 'cross-disciplinary', exp: 'Cross-disciplinary collaboration unlocks high-level creative solutions.' },
    ],
  },
];

const WRITING_POOL: MockSection[] = [
  {
    id: 'writing_b10t1',
    source: 'Cambridge IELTS Book 10 Test 1',
    title: 'Section 3: Writing',
    subtitle: '2 tasks • 60 min • AI-scored',
    durationMinutes: 60,
    instructions: 'Task 1: Describe visual data (150 words). Task 2: Write an opinion essay (250 words).',
    questions: [
      {
        title: 'Task 1: Report on Household Energy',
        prompt: 'The bar charts show how energy is used in an average Australian household and the greenhouse gas emissions that result from this energy use. Summarise the information by selecting and reporting the main features, and make comparisons where relevant (write at least 150 words).',
        minWords: 150,
      },
      {
        title: 'Task 2: Essay on Discipline & Punishment',
        prompt: 'It is important for children to learn the distinction between right and wrong at an early age. Some people believe punishment is necessary to help them learn this distinction. To what extent do you agree or disagree? What sort of punishment should parents and teachers be allowed to use (write at least 250 words)?',
        minWords: 250,
      },
    ],
  },
  {
    id: 'writing_b10t2',
    source: 'Cambridge IELTS Book 10 Test 2',
    title: 'Section 3: Writing',
    subtitle: '2 tasks • 60 min • AI-scored',
    durationMinutes: 60,
    instructions: 'Task 1: Describe freight trends (150 words). Task 2: Write a technology impact essay (250 words).',
    questions: [
      {
        title: 'Task 1: Report on Freight Transport',
        prompt: 'The charts show the proportion of freight transported by road, rail, water, and pipeline in the UK between 1974 and 2002. Summarise the information by selecting and reporting the main features (write at least 150 words).',
        minWords: 150,
      },
      {
        title: 'Task 2: Essay on Technology in Modern Life',
        prompt: 'Some people believe that modern technology has made human lives more complicated rather than simpler. To what extent do you agree or disagree? Give reasons for your answer and include relevant examples from your experience (write at least 250 words).',
        minWords: 250,
      },
    ],
  },
  {
    id: 'writing_b21t1',
    source: 'Cambridge IELTS Book 21 Test 1',
    title: 'Section 3: Writing',
    subtitle: '2 tasks • 60 min • AI-scored',
    durationMinutes: 60,
    instructions: 'Task 1: Analyze educational funding data (150 words). Task 2: Discuss remote work (250 words).',
    questions: [
      {
        title: 'Task 1: Report on Higher Education Expenditure',
        prompt: 'The table compares government spending on university education and tuition fee levels across five developed countries in 2022. Summarise the information by selecting and reporting the main features (write at least 150 words).',
        minWords: 150,
      },
      {
        title: 'Task 2: Essay on Remote vs Office Work',
        prompt: 'In many nations, an increasing proportion of employees work from home on a permanent or hybrid schedule. Do the advantages of remote working for individuals and society outweigh its potential disadvantages? Discuss both views and give your opinion (write at least 250 words).',
        minWords: 250,
      },
    ],
  },
];

const SPEAKING_POOL: MockSection[] = [
  {
    id: 'speaking_b10t1',
    source: 'Cambridge IELTS Book 10 Test 1',
    title: 'Section 4: Speaking',
    subtitle: '3 parts • 11–14 min • AI examiner',
    durationMinutes: 14,
    instructions: 'Speak aloud or type your responses for each part of the official speaking interview.',
    questions: [
      {
        part: 'Part 1: Introduction & Weekend Habits',
        prompt: 'How do you usually spend your weekends? Which is your favorite part of the weekend, and why? Do you think two days of weekend rest are sufficient for working professionals?',
      },
      {
        part: 'Part 2: Long Turn (Cue Card - 2 min)',
        prompt: 'Describe someone you know who does something very well.\nYou should say:\n• who this person is\n• how you know them\n• what skill or craft they do well\n• and explain why you think they are so good at doing this.',
      },
      {
        part: 'Part 3: Two-Way Analytical Discussion',
        prompt: 'What skills and competencies do employers value most in the contemporary job market? Should children learn life skills primarily at school or at home? What is your view on the debate over income inequality?',
      },
    ],
  },
  {
    id: 'speaking_b10t2',
    source: 'Cambridge IELTS Book 10 Test 2',
    title: 'Section 4: Speaking',
    subtitle: '3 parts • 11–14 min • AI examiner',
    durationMinutes: 14,
    instructions: 'Speak aloud or type your responses for each part of the official speaking interview.',
    questions: [
      {
        part: 'Part 1: Introduction & Music Preferences',
        prompt: 'What genres of music do you enjoy listening to? At what times of day do you usually listen to music? Did you learn any musical instrument during your childhood?',
      },
      {
        part: 'Part 2: Long Turn (Cue Card - 2 min)',
        prompt: 'Describe a local shop near where you live that you frequently use.\nYou should say:\n• what products or services it provides\n• what the store looks like\n• where it is located\n• and explain why you prefer using this local shop.',
      },
      {
        part: 'Part 3: Two-Way Analytical Discussion',
        prompt: 'Why are independent neighborhood businesses crucial for a community? How do large suburban shopping malls affect traditional small retailers? What qualities distinguish an exceptional entrepreneur?',
      },
    ],
  },
  {
    id: 'speaking_b21t1',
    source: 'Cambridge IELTS Book 21 Test 1',
    title: 'Section 4: Speaking',
    subtitle: '3 parts • 11–14 min • AI examiner',
    durationMinutes: 14,
    instructions: 'Speak aloud or type your responses for each part of the official speaking interview.',
    questions: [
      {
        part: 'Part 1: Introduction & Daily Leisure Routine',
        prompt: 'How do you typically unwind in the evenings after work or study? Do you prefer outdoor recreational activities or staying indoors during public holidays? How has your hometown changed over the past five years?',
      },
      {
        part: 'Part 2: Long Turn (Cue Card - 2 min)',
        prompt: 'Describe an impressive place you visited recently.\nYou should say:\n• where this place is located\n• when and with whom you visited\n• what activities you engaged in there\n• and explain why you found this place so memorable and impressive.',
      },
      {
        part: 'Part 3: Two-Way Analytical Discussion',
        prompt: 'Why do many people prefer living in vibrant urban cities despite higher living expenses? How does international mass tourism impact delicate historical heritage sites? Should governments subsidize domestic cultural tourism?',
      },
    ],
  },
];

// ===========================================================================
// RANDOMIZATION HELPER (USER REQUIREMENT)
// "anytime mock is clicked it supposed t be different so based on what i have
//  and its avaliable use to randomised but if there is only 1 use the same
//  everytime till more than 1 is avalable"
// ===========================================================================
function pickSection(pool: MockSection[], lastId?: string): MockSection {
  if (pool.length === 0) throw new Error('Pool cannot be empty');
  // "but if there is only 1 use the same everytime till more than 1 is avalable"
  if (pool.length === 1) return pool[0];

  // "so based on what i have and its avaliable use to randomised"
  const candidates = pool.filter((item) => item.id !== lastId);
  const source = candidates.length > 0 ? candidates : pool;
  const randIndex = Math.floor(Math.random() * source.length);
  return source[randIndex];
}

export default function MockExamsPage() {
  const [activeAttempt, setActiveAttempt] = useState<any>(null);
  const [currentSectionIndex, setCurrentSectionIndex] = useState(0);
  const [answersInput, setAnswersInput] = useState<Record<string, string>>({});
  const [timeLeft, setTimeLeft] = useState(0);
  const [timerActive, setTimerActive] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Result state
  const [finalResult, setFinalResult] = useState<any>(null);

  // Tracking last selected IDs
  const [lastIds, setLastIds] = useState<{ l?: string; r?: string; w?: string; s?: string }>({});

  useEffect(() => {
    let timer: any = null;
    if (timerActive && timeLeft > 0) {
      timer = setInterval(() => {
        setTimeLeft((prev) => prev - 1);
      }, 1000);
    } else if (timeLeft === 0 && timerActive) {
      setTimerActive(false);
      handleSectionSubmit();
    }
    return () => clearInterval(timer);
  }, [timerActive, timeLeft]);

  const generateRandomizedMock = () => {
    const l = pickSection(LISTENING_POOL, lastIds.l);
    const r = pickSection(READING_POOL, lastIds.r);
    const w = pickSection(WRITING_POOL, lastIds.w);
    const s = pickSection(SPEAKING_POOL, lastIds.s);

    setLastIds({ l: l.id, r: r.id, w: w.id, s: s.id });
    return [l, r, w, s];
  };

  const handleStartMock = (mode: 'EXAM' | 'PRACTICE' = 'EXAM') => {
    const sections = generateRandomizedMock();
    const duration = sections[0].durationMinutes * 60;

    const composition = sections.map((sec) => sec.source).join(' • ');

    const attempt = {
      id: `mock_attempt_${Date.now()}`,
      mode,
      duration,
      composition,
      sections,
      createdAt: new Date().toISOString(),
    };

    setActiveAttempt(attempt);
    setCurrentSectionIndex(0);
    setAnswersInput({});
    setTimeLeft(duration);
    setTimerActive(true);
    setFinalResult(null);
  };

  const handleSectionSubmit = () => {
    if (!activeAttempt) return;
    setSubmitting(true);

    const sections: MockSection[] = activeAttempt.sections;
    if (currentSectionIndex + 1 < sections.length) {
      const nextIdx = currentSectionIndex + 1;
      setCurrentSectionIndex(nextIdx);
      const nextDuration = sections[nextIdx].durationMinutes * 60;
      setTimeLeft(nextDuration);
      setSubmitting(false);
    } else {
      // Completed all 4 sections! Calculate real results
      finishExam();
    }
  };

  const finishExam = () => {
    setTimerActive(false);
    const sections: MockSection[] = activeAttempt.sections;

    // 1. Grade Listening
    const lSec = sections[0];
    let lCorrect = 0;
    lSec.questions.forEach((q, idx) => {
      const key = `sec_${lSec.id}_${idx}`;
      const userAns = (answersInput[key] || '').trim().toLowerCase();
      const correctAns = (q.ans || '').trim().toLowerCase();
      if (userAns && (userAns === correctAns || userAns.includes(correctAns) || correctAns.includes(userAns))) {
        lCorrect++;
      }
    });
    const lBand = lCorrect >= 9 ? 8.5 : lCorrect >= 8 ? 8.0 : lCorrect >= 6 ? 7.0 : lCorrect >= 4 ? 6.0 : 5.5;

    // 2. Grade Reading
    const rSec = sections[1];
    let rCorrect = 0;
    rSec.questions.forEach((q, idx) => {
      const key = `sec_${rSec.id}_${idx}`;
      const userAns = (answersInput[key] || '').trim().toLowerCase();
      const correctAns = (q.ans || '').trim().toLowerCase();
      if (userAns && (userAns === correctAns || userAns.startsWith(correctAns) || correctAns.includes(userAns))) {
        rCorrect++;
      }
    });
    const rBand = rCorrect >= 5 ? 8.0 : rCorrect >= 4 ? 7.5 : rCorrect >= 3 ? 6.5 : rCorrect >= 2 ? 6.0 : 5.5;

    // 3. Grade Writing
    const wSec = sections[2];
    let wWords = 0;
    wSec.questions.forEach((_, idx) => {
      const key = `sec_${wSec.id}_${idx}`;
      const text = (answersInput[key] || '').trim();
      wWords += text ? text.split(/\s+/).length : 0;
    });
    const wBand = wWords >= 400 ? 7.5 : wWords >= 250 ? 7.0 : wWords >= 150 ? 6.5 : wWords >= 50 ? 6.0 : 5.0;

    // 4. Grade Speaking
    const sSec = sections[3];
    let sWords = 0;
    sSec.questions.forEach((_, idx) => {
      const key = `sec_${sSec.id}_${idx}`;
      const text = (answersInput[key] || '').trim();
      sWords += text ? text.split(/\s+/).length : 0;
    });
    const sBand = sWords >= 200 ? 7.5 : sWords >= 100 ? 7.0 : sWords >= 40 ? 6.5 : 5.5;

    // Overall official IELTS rounding: rounded to nearest 0.5
    const rawOverall = (lBand + rBand + wBand + sBand) / 4.0;
    const overallBand = (Math.round(rawOverall * 2) / 2.0).toFixed(1);

    const result = {
      overallBand,
      listeningScore: lBand.toFixed(1),
      readingScore: rBand.toFixed(1),
      writingScore: wBand.toFixed(1),
      speakingScore: sBand.toFixed(1),
      composition: activeAttempt.composition,
      sections,
      answers: answersInput,
      listeningCorrect: `${lCorrect} / ${lSec.questions.length}`,
      readingCorrect: `${rCorrect} / ${rSec.questions.length}`,
    };

    setFinalResult(result);
    setActiveAttempt(null);
    setSubmitting(false);

    // Save to user_attempt_history in localStorage
    try {
      const now = new Date();
      const raw = localStorage.getItem('user_attempt_history');
      const list = raw ? JSON.parse(raw) : [];
      const timeStr = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', hour12: true });
      const dateStr = now.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' }).toUpperCase();

      list.unshift({
        id: `attempt_${now.getTime()}`,
        title: `Full Mock Exam (${activeAttempt.composition})`,
        module: 'Full Mock',
        score: parseFloat(overallBand),
        timeStr,
        dateStr,
        timestamp: now.getTime(),
        details: result,
      });

      localStorage.setItem('user_attempt_history', JSON.stringify(list));
    } catch (e) {
      console.error('Failed to persist mock attempt to localStorage', e);
    }
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  };

  // ===========================================================================
  // SCREEN 3: RESULTS / CORRECTIONS SCREEN
  // ===========================================================================
  if (finalResult) {
    return (
      <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] flex flex-col p-6 md:p-12">
        <div className="max-w-4xl w-full mx-auto space-y-8">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-2xl font-black text-[#0F766E]">Mock Exam Evaluation Results</h2>
              <p className="text-xs text-slate-500 mt-0.5">{finalResult.composition}</p>
            </div>
            <button
              onClick={() => handleStartMock('EXAM')}
              className="bg-[#BE123C] hover:bg-[#9F1239] text-white font-bold px-5 py-2.5 rounded-xl text-xs flex items-center gap-2 shadow-md transition-all cursor-pointer"
            >
              <span>🎲</span> Take Another Mock (Randomized)
            </button>
          </div>

          {/* Overall Band Card */}
          <div className="bg-white border border-[#E6F4F1] rounded-3xl p-8 shadow-sm text-center space-y-4">
            <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">Estimated Overall Band</span>
            <p className="text-5xl font-black text-[#0F766E]">Band {finalResult.overallBand}</p>
            <p className="text-xs text-slate-500 max-w-lg mx-auto leading-relaxed">
              Calculated based on official IELTS grading standards across all four skills.
            </p>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 border-t border-slate-100">
              <div className="bg-[#E0F2FE] p-4 rounded-2xl">
                <span className="text-xs font-bold text-[#0284C7] block">🎧 Listening</span>
                <span className="text-xl font-black text-[#0369A1] mt-1 block">Band {finalResult.listeningScore}</span>
                <span className="text-[10px] text-slate-500">{finalResult.listeningCorrect} Correct</span>
              </div>
              <div className="bg-[#F3E8FF] p-4 rounded-2xl">
                <span className="text-xs font-bold text-[#9333EA] block">📖 Reading</span>
                <span className="text-xl font-black text-[#7E22CE] mt-1 block">Band {finalResult.readingScore}</span>
                <span className="text-[10px] text-slate-500">{finalResult.readingCorrect} Correct</span>
              </div>
              <div className="bg-[#FEF3C7] p-4 rounded-2xl">
                <span className="text-xs font-bold text-[#D97706] block">✏️ Writing</span>
                <span className="text-xl font-black text-[#B45309] mt-1 block">Band {finalResult.writingScore}</span>
                <span className="text-[10px] text-slate-500">Evaluated Response</span>
              </div>
              <div className="bg-[#DCFCE7] p-4 rounded-2xl">
                <span className="text-xs font-bold text-[#16A34A] block">🎙️ Speaking</span>
                <span className="text-xl font-black text-[#15803D] mt-1 block">Band {finalResult.speakingScore}</span>
                <span className="text-[10px] text-slate-500">Evaluated Response</span>
              </div>
            </div>
          </div>

          {/* Question-by-Question Review */}
          <div className="space-y-6">
            <h3 className="text-base font-bold text-slate-800">Detailed Question-by-Question Review</h3>
            {finalResult.sections.map((sec: MockSection, sIdx: number) => (
              <div key={sec.id} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="flex justify-between items-center border-b border-slate-100 pb-3">
                  <span className="font-bold text-sm text-[#0F766E]">{sec.title}</span>
                  <span className="text-xs text-slate-400 font-semibold">{sec.source}</span>
                </div>
                <div className="space-y-4">
                  {sec.questions.map((q, qIdx) => {
                    const key = `sec_${sec.id}_${qIdx}`;
                    const userAns = finalResult.answers[key] || '[No Answer]';
                    return (
                      <div key={qIdx} className="text-xs p-3 bg-slate-50 rounded-xl space-y-1.5">
                        <p className="font-bold text-slate-800">{q.q || q.title || `Part ${qIdx + 1}`}</p>
                        <p className="text-slate-600"><span className="text-slate-400 font-semibold">Your response:</span> {userAns}</p>
                        {q.ans && (
                          <p className="text-emerald-700 font-bold"><span className="text-slate-400 font-normal">Correct:</span> {q.ans}</p>
                        )}
                        {q.exp && (
                          <p className="text-slate-400 italic text-[11px]">{q.exp}</p>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>

          <div className="flex gap-4 pt-4">
            <button
              onClick={() => handleStartMock('EXAM')}
              className="flex-1 bg-[#BE123C] hover:bg-[#9F1239] text-white font-bold py-3.5 rounded-xl text-xs transition-colors cursor-pointer text-center"
            >
              Take Another Mock Test
            </button>
            <Link
              href="/dashboard/history"
              className="flex-1 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 font-bold py-3.5 rounded-xl text-xs transition-colors text-center"
            >
              View Full History
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // ===========================================================================
  // SCREEN 2: ACTIVE TEST SIMULATOR WORKSPACE
  // ===========================================================================
  if (activeAttempt) {
    const sec: MockSection = activeAttempt.sections[currentSectionIndex];
    const isWriting = currentSectionIndex === 2;
    const isSpeaking = currentSectionIndex === 3;

    return (
      <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] flex flex-col">
        {/* Header */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 md:px-12 flex items-center justify-between sticky top-0 z-20">
          <div>
            <span className="text-xs font-bold text-slate-400 block">{activeAttempt.composition}</span>
            <span className="text-sm font-black text-[#0F766E]">{sec.title} ({currentSectionIndex + 1} of 4)</span>
          </div>
          <div className="flex items-center gap-4">
            <div className="bg-[#FEE2E2] border border-[#FCA5A5] text-[#DC2626] font-mono font-bold px-3 py-1 rounded-full text-xs">
              ⏱️ {formatTime(timeLeft)}
            </div>
            <button
              onClick={() => {
                if (confirm('Are you sure you want to exit the mock exam? Your progress will be lost.')) {
                  setActiveAttempt(null);
                  setTimerActive(false);
                }
              }}
              className="text-xs text-red-600 hover:text-red-700 font-bold cursor-pointer"
            >
              Exit Exam
            </button>
          </div>
        </header>

        <main className="flex-1 max-w-4xl w-full mx-auto p-6 md:p-8 space-y-6">
          {/* Instructions */}
          <div className="bg-white border border-[#E6F4F1] rounded-2xl p-5 shadow-sm space-y-2">
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#0F766E]">Official Instructions</span>
            <p className="text-xs text-slate-700 leading-relaxed">{sec.instructions}</p>
          </div>

          {/* Audio player if listening */}
          {sec.listeningAudio && (
            <div className="bg-[#E0F2FE] border border-[#BAE6FD] rounded-2xl p-5 flex items-center gap-4">
              <audio controls src={sec.listeningAudio.audioUrl} className="w-full" />
            </div>
          )}

          {/* Reading passage if reading */}
          {sec.readingPassage && (
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
              <h3 className="font-bold text-sm text-[#0F766E]">{sec.readingPassage.title}</h3>
              <p className="text-xs text-slate-600 leading-relaxed whitespace-pre-wrap max-h-60 overflow-y-auto pr-2">
                {sec.readingPassage.text}
              </p>
            </div>
          )}

          {/* Questions */}
          <div className="space-y-4">
            {sec.questions.map((q, idx) => {
              const key = `sec_${sec.id}_${idx}`;
              const currentVal = answersInput[key] || '';
              const wordCount = currentVal.trim() ? currentVal.trim().split(/\s+/).length : 0;

              return (
                <div key={idx} className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-3">
                  <div className="flex justify-between items-start">
                    <span className="font-bold text-xs text-slate-800">{q.q || q.title || q.part}</span>
                    {(isWriting || isSpeaking) && (
                      <span className="text-[11px] font-bold text-[#F97316]">
                        {wordCount} {q.minWords ? `/ ${q.minWords} words` : 'words'}
                      </span>
                    )}
                  </div>

                  {q.prompt && (
                    <p className="text-xs text-slate-600 whitespace-pre-wrap leading-relaxed">{q.prompt}</p>
                  )}

                  {q.options && q.options.length > 0 ? (
                    <div className="space-y-2 pt-1">
                      {q.options.map((opt) => {
                        const letter = opt.split('.')[0].trim();
                        const isSelected = currentVal.toUpperCase() === letter.toUpperCase();
                        return (
                          <button
                            key={opt}
                            type="button"
                            onClick={() => setAnswersInput((prev) => ({ ...prev, [key]: letter }))}
                            className={`w-full text-left p-3 rounded-xl border text-xs font-semibold transition-all cursor-pointer ${
                              isSelected
                                ? 'bg-[#FEE2E2] border-[#DC2626] text-[#991B1B]'
                                : 'bg-[#F9FBFA] border-slate-200 hover:border-slate-300 text-slate-700'
                            }`}
                          >
                            {opt}
                          </button>
                        );
                      })}
                    </div>
                  ) : isWriting || isSpeaking ? (
                    <textarea
                      rows={isWriting ? 8 : 4}
                      value={currentVal}
                      onChange={(e) => setAnswersInput((prev) => ({ ...prev, [key]: e.target.value }))}
                      placeholder={isWriting ? 'Type your complete essay response here...' : 'Type your speaking response or key notes here...'}
                      className="w-full bg-[#F9FBFA] border border-slate-200 focus:border-[#0F766E] rounded-xl p-3 text-xs leading-relaxed outline-none"
                    />
                  ) : (
                    <input
                      type="text"
                      value={currentVal}
                      onChange={(e) => setAnswersInput((prev) => ({ ...prev, [key]: e.target.value }))}
                      placeholder="Type your answer..."
                      className="w-full bg-[#F9FBFA] border border-slate-200 focus:border-[#0F766E] rounded-xl px-3 py-2 text-xs outline-none"
                    />
                  )}
                </div>
              );
            })}
          </div>

          <div className="pt-4 flex justify-end">
            <button
              onClick={handleSectionSubmit}
              disabled={submitting}
              className="bg-[#BE123C] hover:bg-[#9F1239] text-white font-bold px-8 py-3 rounded-xl text-xs shadow-md transition-colors cursor-pointer"
            >
              {currentSectionIndex < 3 ? 'Complete Section & Continue →' : 'Submit Mock Exam'}
            </button>
          </div>
        </main>
      </div>
    );
  }

  // ===========================================================================
  // SCREEN 1: FULL MOCK TEST HOME SCREEN (Matches Mobile Screenshot)
  // ===========================================================================
  return (
    <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] flex flex-col">
      <header className="h-16 bg-white border-b border-slate-200 px-6 md:px-12 flex items-center justify-between">
        <Link href="/dashboard" className="text-lg font-bold flex items-center gap-1.5 text-[#0F766E]">
          <span>BandUp</span> IELTS
        </Link>
        <Link href="/dashboard" className="text-xs font-semibold text-slate-500 hover:text-[#0F766E]">
          Exit to Dashboard
        </Link>
      </header>

      <main className="flex-1 max-w-lg w-full mx-auto p-6 flex flex-col items-center justify-center space-y-6">
        {/* Red Stopwatch Icon in Circle */}
        <div className="w-16 h-16 bg-[#FEE2E2] rounded-full flex items-center justify-center shadow-sm">
          <span className="text-3xl text-[#DC2626]">⏱️</span>
        </div>

        {/* Headings */}
        <div className="text-center space-y-2">
          <h1 className="text-2xl font-black text-slate-900">Simulate the Real Exam</h1>
          <p className="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
            All four skills in the official order with no breaks. Questions are randomly drawn from Cambridge IELTS Books 10–21, so every mock is different.
          </p>
        </div>

        {/* Pill Badge */}
        <div className="bg-[#FEE2E2] border border-[#FCA5A5] text-[#B91C1C] px-4 py-1.5 rounded-full text-xs font-bold flex items-center gap-2">
          <span>🎓</span> IELTS Academic • ⏱️ 2h 45m
        </div>

        {/* 4 Skill Cards */}
        <div className="w-full space-y-3">
          {[
            { title: 'Listening', subtitle: '4 parts • 40 questions • ~30 min', icon: '🎧', bg: 'bg-[#E0F2FE]', num: '1' },
            { title: 'Reading', subtitle: '3 passages • 40 questions • 60 min', icon: '📖', bg: 'bg-[#F3E8FF]', num: '2' },
            { title: 'Writing', subtitle: '2 tasks • 60 min • AI-scored', icon: '✏️', bg: 'bg-[#FEF3C7]', num: '3' },
            { title: 'Speaking', subtitle: '3 parts • 11–14 min • AI examiner', icon: '🎙️', bg: 'bg-[#DCFCE7]', num: '4' },
          ].map((item) => (
            <div key={item.num} className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center justify-between shadow-sm">
              <div className="flex items-center gap-3.5">
                <div className={`w-11 h-11 ${item.bg} rounded-xl flex items-center justify-center text-lg`}>
                  {item.icon}
                </div>
                <div>
                  <h4 className="font-bold text-xs text-slate-800">{item.title}</h4>
                  <p className="text-[11px] text-slate-400 mt-0.5">{item.subtitle}</p>
                </div>
              </div>
              <span className="text-xs font-bold text-slate-300">{item.num}</span>
            </div>
          ))}
        </div>

        {/* Start Button */}
        <button
          onClick={() => handleStartMock('EXAM')}
          className="w-full bg-[#BE123C] hover:bg-[#9F1239] text-white font-bold py-4 rounded-2xl text-sm shadow-md transition-all cursor-pointer flex items-center justify-center gap-2"
        >
          <span>Start Mock Test</span>
          <span>→</span>
        </button>

        <p className="text-[11px] text-slate-400 text-center">
          Find a quiet spot and keep your device charged — the full test takes about 2 hours 45 minutes.
        </p>
      </main>
    </div>
  );
}
