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

const book10Test3Questions: Question[] = [
  {
    question: 'Do you enjoy travelling? [Why/Why not?]',
    audioAsset: 'q1.mp3',
    duration: 1.73,
    part: 1,
    transcript: 'Actually, I really enjoy travelling. It is one of my favorite hobbies because it allows me to experience different cultures and escape the daily grind. Exploring new cities and trying local cuisines is incredibly refreshing for me.',
  },
  {
    question: 'Have you done much travelling? [Why/Why not?]',
    audioAsset: 'q2.mp3',
    duration: 1.68,
    part: 1,
    transcript: "I have done a fair amount of travelling, although not as much as I would like. I have visited several countries across Europe and Asia, which has significantly broadened my perspective on the world. I hope to travel much more once my schedule becomes less hectic.",
  },
  {
    question: "Do you think it's better to travel alone or with other people? [Why?]",
    audioAsset: 'q3.mp3',
    duration: 4.08,
    part: 1,
    transcript: "I personally prefer travelling with other people, such as close friends or family. Sharing experiences makes the journey much more memorable and enjoyable. However, I can see why some prefer the independence of solo travel, though I find it a bit lonely.",
  },
  {
    question: 'Where would you like to travel in the future? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.18,
    part: 1,
    transcript: 'I would love to travel to Japan in the near future. I have always been fascinated by the unique blend of ancient traditions and modern technology there. Specifically, I am keen to visit Kyoto during the cherry blossom season to see the beautiful landscape.',
  },
  {
    question: 'Describe a child that you know.',
    audioAsset: 'q5.mp3',
    duration: 1.90,
    part: 2,
    youShouldSay: [
      'who this child is and how often you see him or her',
      'how old this child is',
      'what he or she is like',
      'and explain what you feel about this child.',
    ],
    transcript: 'I would like to talk about my nephew, Leo, who is currently six years old. I see him quite frequently because he lives just a few streets away from my family home. He is an incredibly energetic and imaginative boy with a very curious nature. What I find most fascinating about him is his passion for building complex structures with toy blocks; he can spend hours focused entirely on his creations. Spending time with him is always a delight because he has a contagious sense of humor and a very kind heart.',
  },
  {
    question: 'How much time do children spend with their parents in your country? Do you think that is enough?',
    audioAsset: 'q6.mp3',
    duration: 5.14,
    part: 3,
    transcript: 'In my country, many parents work long hours, so children often spend weekdays at school or after-school care, leaving only evenings and weekends for family interaction. While many families try their best to spend quality time together on weekends, I feel it is often insufficient because children thrive when they have regular, stress-free parental engagement every day.',
  },
  {
    question: 'How important do you think spending time together is for the relationships between parents and children? Why?',
    audioAsset: 'q7.mp3',
    duration: 6.10,
    part: 3,
    transcript: 'I believe spending time together is fundamentally crucial for developing emotional security and strong bonds of trust. When parents actively converse and engage in shared activities with their children, children feel valued, communicate more openly, and develop higher self-esteem and social empathy.',
  },
  {
    question: 'Have relationships between parents and children changed in recent years? Why do you think that is?',
    audioAsset: 'q8.mp3',
    duration: 4.94,
    part: 3,
    transcript: "Yes, family dynamics have shifted noticeably. Today, relationships tend to be more democratic and less authoritarian than in the past, with parents listening more closely to their children's opinions. On the other hand, the pervasive use of smartphones and digital devices has created digital barriers where family members might be in the same room but absorbed in separate screens.",
  },
  {
    question: 'What are the most popular free-time activities with children today?',
    audioAsset: 'q9.mp3',
    duration: 3.70,
    part: 3,
    transcript: "Nowadays, the most popular free-time activities are heavily centered around digital media, such as video gaming, watching video streams on tablets, and interacting on social media apps. While outdoor sports like football, swimming, and cycling remain popular, screen-based entertainment definitely dominates children's recreation today.",
  },
  {
    question: 'Do you think the free-time activities children do today are good for their health? Why is that?',
    audioAsset: 'q10.mp3',
    duration: 5.14,
    part: 3,
    transcript: 'Generally speaking, many contemporary activities are detrimental to physical health because sedentary screen time can lead to poor posture, reduced physical stamina, and increased risks of childhood obesity. However, some digital games do stimulate strategic thinking and problem-solving skills, so a healthy balance between screen time and active outdoor play is essential.',
  },
  {
    question: "How do you think children's activities will change in the future? Will this be a positive change?",
    audioAsset: 'q11.mp3',
    duration: 5.04,
    part: 3,
    transcript: "In the future, I anticipate that immersive virtual and augmented reality technologies will play a much bigger role in children's education and play. If designed well, these immersive simulations could encourage active physical movement and global collaboration. However, if overused, they might further detach young people from genuine real-world physical interactions, making moderate use and parental guidance critical.",
  },
];

const book10Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (School)
  {
    question: 'Did you go to secondary/high school near to where you lived? [Why/Why not?]',
    audioAsset: 'q1.mp3',
    duration: 3.5,
    part: 1,
    transcript: 'Actually, my high school was located quite far from my home, about a forty-minute bus ride away. Because of this, I had to wake up very early every morning to catch the school transport, which was quite exhausting, but it did teach me the value of time management.',
  },
  {
    question: 'What do you like about your secondary/high school? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 3.0,
    part: 1,
    transcript: 'What I truly appreciated about my secondary school was the incredible variety of extracurricular activities on offer. Specifically, I loved the drama club because it allowed me to build my confidence and meet students from different year groups, which made the school environment feel much more inclusive.',
  },
  {
    question: "Tell me about anything you didn't like at your school.",
    audioAsset: 'q3.mp3',
    duration: 3.2,
    part: 1,
    transcript: 'One aspect I found quite frustrating was the lack of modern facilities in our science laboratories. The equipment was rather outdated, which made conducting experiments quite difficult, and I often felt that we were not as prepared for university-level studies as we could have been.',
  },
  {
    question: 'How do you think your school could be improved? [Why/Why not?]',
    audioAsset: 'q4.mp3',
    duration: 3.5,
    part: 1,
    transcript: 'I believe my school could have been significantly improved by investing in better digital resources and high-speed internet access for students. If we had more interactive technology in the classrooms, the lessons would have been much more engaging and relevant to the modern world.',
  },

  // Part 2: Question 5 (Cue Card: Possessions)
  {
    question: "Describe something you don't have now but would really like to own in the future.",
    audioAsset: 'q5.mp3',
    duration: 3.0,
    part: 2,
    youShouldSay: [
      'what this thing is',
      'how long you have wanted to own it',
      'where you first saw it',
      'and explain why you would like to own it.',
    ],
    transcript: 'One thing I would really love to own in the future is a high-end electric vehicle, specifically a Tesla. Currently, I rely on public transportation, which can be quite time-consuming and inconvenient during peak hours. Owning an electric car would provide me with the independence to travel whenever I choose while also being an environmentally friendly choice. I have been following the latest advancements in battery technology and self-driving features, which fascinate me. Hopefully, as my career progresses and I become more financially stable, I will be able to make this purchase a reality within the next few years.',
  },

  // Part 3: Questions 6-12 (Possessions / Consumerism)
  {
    question: 'What types of things do young people in your country most want to own today? Why is this?',
    audioAsset: 'q6.mp3',
    duration: 4.0,
    part: 3,
    transcript: 'In my country, young people are particularly drawn to owning the latest technological gadgets, such as smartphones and high-end laptops. This is largely driven by the rapid pace of digital innovation and the desire to stay connected with social trends. Additionally, there is a strong cultural emphasis on status, where possessing these items serves as a visible marker of personal success.',
  },
  {
    question: 'Why do some people feel they need to own things?',
    audioAsset: 'q7.mp3',
    duration: 3.5,
    part: 3,
    transcript: 'Many people feel a psychological need to own things because possessions often provide a sense of security and identity. In a consumerist society, we are conditioned to believe that acquiring material goods will enhance our social standing. Furthermore, some individuals use shopping as a way to cope with stress or to fill an emotional void in their lives.',
  },
  {
    question: 'Do you think that owning lots of things makes people happy? Why?',
    audioAsset: 'q8.mp3',
    duration: 4.0,
    part: 3,
    transcript: "I do not believe that owning a vast number of things leads to genuine happiness. While new possessions might provide a temporary thrill or a 'dopamine hit,' this satisfaction is usually short-lived. True fulfillment, in my opinion, comes from meaningful relationships, personal growth, and experiences rather than the accumulation of material objects.",
  },
  {
    question: 'Do you think television and films can make people want to get new possessions?',
    audioAsset: 'q9.mp3',
    duration: 4.0,
    part: 3,
    transcript: 'Yes, television and films have a profound influence on consumer desires. Through highly polished advertisements and product placement in popular movies, brands create an aspirational lifestyle that viewers want to emulate. When we see our favorite celebrities using certain products, it reinforces the belief that owning those items will make us more attractive or successful.',
  },
  {
    question: 'Why do they have this effect?',
    audioAsset: 'q10.mp3',
    duration: 3.0,
    part: 3,
    transcript: "This effect is powerful because media taps into our subconscious desires for social belonging and status. Advertisers use psychological triggers to suggest that their products are essential for a 'better' life. By associating their items with happiness, beauty, or prestige, they make it difficult for viewers to distinguish between actual needs and manufactured wants.",
  },
  {
    question: 'Are there any benefits to society of people wanting to get new possessions? Why do you think that is?',
    audioAsset: 'q11.mp3',
    duration: 4.5,
    part: 3,
    transcript: "There are some economic benefits, as high consumer demand stimulates growth and creates jobs in manufacturing and retail sectors. However, there are significant drawbacks as well, such as environmental degradation due to overconsumption. While it keeps the economy moving, it often leads to a 'throwaway culture' that is unsustainable in the long term.",
  },
  {
    question: 'Do you think people will consider that having lots of possessions is a sign of success in the future?',
    audioAsset: 'q12.mp3',
    duration: 4.5,
    part: 3,
    transcript: "I believe that as society evolves, the definition of success will shift away from material possessions. People are becoming increasingly conscious of sustainability and the negative impacts of consumerism. I suspect that in the future, success will be measured more by one's contribution to society, personal well-being, and life experiences rather than the number of luxury items one owns.",
  },
];

const book11Test1Questions: Question[] = [
  // Part 1: Questions 1-4 (Food & Cooking)
  {
    question: 'What sorts of food do you like eating most? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 1.9,
    part: 1,
    transcript: 'I enjoy eating a wide variety of fresh, home-cooked Mediterranean and Asian dishes, particularly those rich in herbs, vegetables, and lean proteins. I love these foods because they are nutritious, flavorful, and leave me feeling energized rather than sluggish.',
  },
  {
    question: 'Who normally does the cooking in your home? [Why/Why not?]',
    audioAsset: 'q2.mp3',
    duration: 1.9,
    part: 1,
    transcript: 'In my household, cooking is a shared responsibility, though my mother does most of the daily preparation. She truly enjoys experimenting with traditional recipes, whereas I step in on weekends to cook modern international meals for the family.',
  },
  {
    question: 'Do you watch cookery programmes on TV? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.2,
    part: 1,
    transcript: 'Yes, I occasionally watch culinary shows and cooking competitions on television. I find them visually engaging and educational, as they provide great culinary inspiration and teach useful techniques for improving my own kitchen skills.',
  },
  {
    question: 'In general, do you prefer eating out or eating at home? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.7,
    part: 1,
    transcript: 'Generally speaking, I prefer eating at home because it allows complete control over ingredient quality, hygiene, and nutrition. However, I do enjoy dining out periodically to socialize with friends and try authentic cuisines that are complex to prepare.',
  },

  // Part 2: Question 5 (Cue Card - House/Apartment)
  {
    question: 'Describe a house/apartment that someone you know lives in.',
    audioAsset: 'q5.mp3',
    duration: 3.2,
    part: 2,
    youShouldSay: [
      'whose house/apartment this is',
      'where the house/apartment is',
      'what it looks like inside',
      "and explain what you like or dislike about this person's house/apartment.",
    ],
    transcript: "I would like to describe my close friend's apartment, which is located in a modern high-rise in the city center. Inside, it features an open-plan layout with large floor-to-ceiling windows that fill the living space with natural light. What I particularly love about her apartment is the cozy minimalist interior design and the breathtaking panoramic view of the city skyline, though it can occasionally be noisy due to downtown traffic.",
  },

  // Part 3: Questions 6-11 (Discussion - Housing & Accommodation)
  {
    question: 'What kinds of home are most popular in your country? Why is this?',
    audioAsset: 'q6.mp3',
    duration: 2.7,
    part: 3,
    transcript: 'In my country, detached houses are the most popular choice, particularly for families, because they offer more privacy and outdoor space. Many people aspire to own a house with a garden, as it is seen as a sign of success and provides a better environment for raising children. Recently, however, high-rise apartments have become more common in urban centers due to rapid population growth and limited land availability.',
  },
  {
    question: 'What do you think are the advantages of living in a house rather than an apartment?',
    audioAsset: 'q7.mp3',
    duration: 3.8,
    part: 3,
    transcript: 'Living in a house offers several significant advantages, most notably the sense of independence and direct access to private outdoor areas like a yard or patio. Unlike apartments, houses generally do not share walls with neighbors, which significantly reduces noise disturbances. Furthermore, home ownership often provides more flexibility for renovations and personal customization, allowing residents to create a space that truly reflects their lifestyle.',
  },
  {
    question: 'Do you think that everyone would like to live in a larger home? Why is that?',
    audioAsset: 'q8.mp3',
    duration: 2.7,
    part: 3,
    transcript: "I believe that most people do aspire to live in a larger home, primarily because it offers more comfort and better storage for personal belongings. A spacious environment can significantly reduce stress and improve one's quality of life, especially for those working from home or raising a family. However, some individuals might prefer a smaller, more manageable space to minimize maintenance efforts and utility costs.",
  },
  {
    question: 'How easy is it to find a place to live in your country?',
    audioAsset: 'q9.mp3',
    duration: 2.7,
    part: 3,
    transcript: 'Finding suitable accommodation in my country has become increasingly challenging in recent years. In major cities, the demand for housing far outstrips supply, which has led to a sharp rise in both property prices and rental rates. Consequently, many young people struggle to find affordable housing, often having to compromise on location or living space to stay within their budgets.',
  },
  {
    question: "Do you think it's better to rent or to buy a place to live in? Why?",
    audioAsset: 'q10.mp3',
    duration: 3.2,
    part: 3,
    transcript: "Deciding between renting and buying is a complex choice that depends heavily on an individual's financial situation and long-term goals. Buying a property is often viewed as a sound investment that provides stability and potential equity growth over time. On the other hand, renting offers greater flexibility, as it allows people to move easily for career opportunities without the burden of property maintenance or high upfront costs.",
  },
  {
    question: 'Do you agree that there is a right age for young adults to stop living with their parents? Why is that?',
    audioAsset: 'q11.mp3',
    duration: 4.3,
    part: 3,
    transcript: "I believe there is no universal 'right' age, as it depends entirely on the cultural norms and economic conditions of the country. In many societies, it is common for young adults to live with their parents until they are financially stable or married, which helps them save money. However, moving out at a younger age can be a vital step toward developing independence, self-reliance, and personal responsibility.",
  },
];

const book11Test2Questions: Question[] = [
  // Part 1: Questions 1-4 (Friends, Neighbours & Family)
  {
    question: 'How often do you go out with friends? [Why/Why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.0,
    part: 1,
    transcript: 'I try to go out with my friends at least once or twice a week, usually on the weekends. We enjoy going to local cafes or catching the latest movies together. It is a great way for me to de-stress after a busy week of work or study. I believe maintaining these social connections is essential for my overall well-being.',
  },
  {
    question: 'Tell me about your best friend at school.',
    audioAsset: 'q2.mp3',
    duration: 2.0,
    part: 1,
    transcript: 'My best friend from school is named Sarah. We have been close since we were about ten years old and we shared a desk in our primary school classroom. She is incredibly kind and has always supported me through difficult times. Even though we live in different cities now, we still make an effort to call each other every weekend.',
  },
  {
    question: 'How friendly are you with your neighbours? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.2,
    part: 1,
    transcript: "I have a very friendly relationship with my neighbors. We often greet each other when we leave for work in the morning and occasionally look after each other's homes when someone is away. It creates a safe and welcoming environment, and I feel quite lucky to live in such a supportive community.",
  },
  {
    question: 'Which is more important to you, friends or family? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.6,
    part: 1,
    transcript: 'Personally, I find family to be more important because they are the foundation of my life. While friends are wonderful for companionship and fun, my family has always been my primary support system through every stage of my life. That said, I do consider close friends to be like a second family, so I value both deeply.',
  },

  // Part 2: Question 5 (Cue Card - Writer)
  {
    question: 'Describe a writer you would like to meet.',
    audioAsset: 'q5.mp3',
    duration: 2.2,
    part: 2,
    youShouldSay: [
      'who the writer is',
      'what you know about this writer already',
      'what you would like to find out about him/her',
      'and explain why you would like to meet this writer.',
    ],
    transcript: "I would love to meet J.K. Rowling, the author of the Harry Potter series. I have been a fan of her writing style since I was a child, as she has an incredible ability to build immersive worlds. I am particularly interested in learning about her creative process and how she manages to develop such complex character arcs over multiple books. Meeting her would be a dream come true, as her work has had a significant impact on my passion for literature. I would ask her how she stays motivated to write even when facing writer's block.",
  },

  // Part 3: Questions 6-11 (Discussion - Books, Reading & Authors)
  {
    question: 'What kinds of book are most popular with children in your country? Why do you think that is?',
    audioAsset: 'q6.mp3',
    duration: 4.8,
    part: 3,
    transcript: "In my country, children are particularly drawn to fantasy novels and comic books, as these genres offer an escape into imaginative worlds. I believe this popularity stems from the vibrant illustrations and the sense of adventure that captivates a young reader's mind, making the reading experience far more engaging than traditional textbooks.",
  },
  {
    question: 'Why do you think some children do not read books very often?',
    audioAsset: 'q7.mp3',
    duration: 3.1,
    part: 3,
    transcript: 'I think many children struggle to find time for reading due to the overwhelming pressure of school assignments and extracurricular activities. Furthermore, the constant distraction of digital media and video games often makes the slower pace of reading seem less appealing compared to the instant gratification provided by screens.',
  },
  {
    question: 'How do you think children can be encouraged to read more?',
    audioAsset: 'q8.mp3',
    duration: 3.0,
    part: 3,
    transcript: 'To encourage more reading, schools and parents could create dedicated, comfortable reading corners that are free from digital distractions. Additionally, introducing interactive book clubs where children can discuss stories with their peers can transform reading from a solitary task into a fun, social experience.',
  },
  {
    question: 'Are there any occasions when reading at speed is a useful skill to have? What are they?',
    audioAsset: 'q9.mp3',
    duration: 3.8,
    part: 3,
    transcript: 'Yes, speed reading is an invaluable skill, particularly in professional or academic environments where one must process large volumes of information quickly. For instance, when reviewing lengthy legal contracts or academic research papers, the ability to scan for key concepts and data is essential for efficiency.',
  },
  {
    question: 'Are there any jobs where people need to read a lot? What are they?',
    audioAsset: 'q10.mp3',
    duration: 3.1,
    part: 3,
    transcript: 'Yes, there are many professions that demand high levels of reading proficiency. For example, lawyers and journalists must constantly read reports, case files, and news articles to stay informed and build their arguments. Similarly, medical professionals need to read extensive research journals to keep up with the latest developments in healthcare.',
  },
  {
    question: 'Do you think that reading novels is more interesting than reading factual books? Why is that?',
    audioAsset: 'q11.mp3',
    duration: 4.2,
    part: 3,
    transcript: 'While factual books are excellent for acquiring specific knowledge, I find novels more interesting because they explore the depth of human emotion and complex character development. Novels allow readers to experience different perspectives and cultures, which creates a more immersive and thought-provoking experience than simply absorbing raw data.',
  },
];

const book11Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Photography)
  {
    question: 'What type of photos do you like taking? [Why/Why not?]',
    audioAsset: 'q1.mp3',
    duration: 1.6,
    part: 1,
    transcript: 'I generally prefer taking landscape photos because I enjoy capturing the beauty of nature while I am traveling. Occasionally, I also like taking candid shots of my friends, as these photos feel more authentic and preserve special memories better than posed pictures.',
  },
  {
    question: 'What do you do with photos you take? [Why/Why not?]',
    audioAsset: 'q2.mp3',
    duration: 1.6,
    part: 1,
    transcript: 'I usually store my photos in digital folders on my computer or upload them to a cloud storage service to ensure they are safe. Sometimes, I select the best ones to share on social media platforms so that my friends and family can see what I have been up to.',
  },
  {
    question: 'When do you visit other places, do you take photos or buy postcards? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 3.2,
    part: 1,
    transcript: 'When I travel, I prefer taking my own photos rather than buying postcards. I feel that personal photographs are more meaningful because they capture my specific perspective and the unique experiences I had during the trip, whereas postcards are quite generic.',
  },
  {
    question: 'Do you like people taking photos of you? [Why/Why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.9,
    part: 1,
    transcript: 'To be honest, I am quite camera-shy, so I generally do not like people taking photos of me. I often feel a bit awkward when I am the center of attention, though I do make exceptions if it is a special occasion like a birthday or a wedding.',
  },

  // Part 2: Question 5 (Cue Card - Perfect Weather)
  {
    question: 'Describe a day when you thought the weather was perfect.',
    audioAsset: 'q5.mp3',
    duration: 2.6,
    part: 2,
    youShouldSay: [
      'where you were on this day',
      'what the weather was like on this day',
      'what you did during the day',
      'and explain why you thought the weather was perfect on this day.',
    ],
    transcript: "One day that stands out in my memory was a crisp autumn afternoon last October. The sky was a brilliant, cloudless blue, and the air had just enough of a chill to make wearing a light sweater feel perfectly cozy. I spent the entire day hiking through a nearby forest where the leaves had turned vibrant shades of amber and gold. The sunlight filtering through the canopy created a warm, golden glow that made everything look picturesque. It was the perfect weather because it wasn't too hot to exert myself, yet it was bright enough to lift my spirits completely.",
  },

  // Part 3: Questions 6-11 (Discussion - Weather & Seasons)
  {
    question: 'What types of weather do people in your country dislike most? Why is that?',
    audioAsset: 'q6.mp3',
    duration: 3.2,
    part: 3,
    transcript: 'In my country, people generally dislike extreme heat and humidity during the summer months because it makes outdoor activities exhausting and uncomfortable. Additionally, prolonged rainy weather is often disliked because it causes traffic congestion and disrupts daily commutes.',
  },
  {
    question: 'What jobs can be affected by different weather conditions? Why?',
    audioAsset: 'q7.mp3',
    duration: 2.9,
    part: 3,
    transcript: 'Many outdoor professions are significantly affected by weather, such as construction workers, farmers, and delivery drivers. For example, heavy rainfall or extreme temperatures can halt construction projects, while farmers rely on specific weather patterns to ensure their crops grow properly.',
  },
  {
    question: 'Are there any important festivals in your country that celebrate a season or type of weather?',
    audioAsset: 'q8.mp3',
    duration: 4.7,
    part: 3,
    transcript: 'Yes, we have several festivals that are linked to the seasons. For instance, the harvest festival is celebrated to mark the end of the agricultural season, and there are various traditional holidays that welcome the arrival of spring after a cold winter.',
  },
  {
    question: "How important do you think it is for everyone to check what the next day's weather will be? Why?",
    audioAsset: 'q9.mp3',
    duration: 5.0,
    part: 3,
    transcript: 'I believe it is quite important because checking the weather allows people to plan their day effectively. For instance, knowing if it will rain helps individuals decide whether to carry an umbrella or choose appropriate clothing, which helps them avoid getting sick or being caught in a storm.',
  },
  {
    question: 'What is the best way to get accurate information about the weather?',
    audioAsset: 'q10.mp3',
    duration: 3.2,
    part: 3,
    transcript: 'The most reliable way to get accurate information is through official meteorological websites or government-backed weather apps. These sources use satellite data and professional forecasting, which are far more dependable than informal social media reports or word-of-mouth.',
  },
  {
    question: 'How easy or difficult is it to predict the weather in your country? Why is that?',
    audioAsset: 'q11.mp3',
    duration: 3.6,
    part: 3,
    transcript: 'Predicting the weather in my country is quite challenging due to our diverse geography. Because we have both coastal and mountainous regions, weather patterns can shift very rapidly, making it difficult for even professional meteorologists to provide perfectly accurate long-term forecasts.',
  },
];

const book11Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (Names)
  {
    question: 'How did you parents choose your name(s)?',
    audioAsset: 'q1.mp3',
    duration: 1.6,
    part: 1,
    transcript: 'My parents chose my name because it has been passed down through several generations in my family. They wanted to honor my grandfather, who was a very respected figure, so they decided to name me after him to keep the family tradition alive.',
  },
  {
    question: 'Does your name have any special meaning?',
    audioAsset: 'q2.mp3',
    duration: 2.1,
    part: 1,
    transcript: "Yes, my name actually has a significant meaning. In my native language, it translates to 'bright light' or 'hope,' which is something my parents wished for me when I was born. It is a very positive name that I am quite proud to carry.",
  },
  {
    question: 'Is your name common or unusual in your country?',
    audioAsset: 'q3.mp3',
    duration: 2.4,
    part: 1,
    transcript: 'My name is actually quite common in my country. You will find that many people in my generation share this name because it was very popular during the decade I was born. It is not unusual at all, and I often meet others with the same name.',
  },
  {
    question: 'If you could change your name, would you? [Why/Why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.8,
    part: 1,
    transcript: 'I would not change my name even if I had the chance. I have become very attached to it over the years, and it is a core part of my identity. Changing it would feel like losing a connection to my family and my own personal history.',
  },

  // Part 2: Question 5 (Cue Card - TV Documentary)
  {
    question: 'Describe a TV documentary you watched that was particularly interesting.',
    audioAsset: 'q5.mp3',
    duration: 3.7,
    part: 2,
    youShouldSay: [
      'what the documentary was about',
      'why you decided to watch it',
      'what you learnt during the documentary',
      'and explain why the TV documentary was particularly interesting.',
    ],
    transcript: "I recently watched a fascinating documentary on Netflix titled 'Our Planet'. It was a visually stunning series that explored the impact of climate change on various ecosystems across the globe. What I found particularly interesting was the high-definition cinematography, which captured animal behaviors that had never been filmed before. It really opened my eyes to the fragility of our environment and the urgent need for conservation efforts. I would highly recommend it to anyone who enjoys nature and wants to learn more about the world.",
  },

  // Part 3: Questions 6-11 (Discussion - Television & Advertising)
  {
    question: 'What are the most popular kinds of TV programmes in your country? Why is this?',
    audioAsset: 'q6.mp3',
    duration: 3.4,
    part: 3,
    transcript: 'In my country, reality shows and talent competitions are incredibly popular. This is largely because they offer a form of escapism and allow viewers to feel a personal connection with the contestants as they progress through the show.',
  },
  {
    question: 'Do you think there are too many game shows on TV nowadays? Why?',
    audioAsset: 'q7.mp3',
    duration: 2.9,
    part: 3,
    transcript: 'I believe there is an oversaturation of game shows on television today. This is likely because they are relatively inexpensive to produce and have proven to be highly effective at keeping audiences engaged through interactive elements.',
  },
  {
    question: 'Do you think TV is the main way for people to get the news in your country? What other ways are there?',
    audioAsset: 'q8.mp3',
    duration: 4.1,
    part: 3,
    transcript: 'While traditional television remains a primary source of news for the older generation, younger people now predominantly rely on social media and news websites. These digital platforms provide real-time updates that TV broadcasts often cannot match.',
  },
  {
    question: 'What types of products are advertised most often on TV?',
    audioAsset: 'q9.mp3',
    duration: 2.9,
    part: 3,
    transcript: 'Products related to health, beauty, and household cleaning are advertised most frequently. These items are targeted at a wide demographic, and companies invest heavily in TV slots to ensure their brand remains at the forefront of consumer awareness.',
  },
  {
    question: 'Do you think that people pay attention to adverts on TV? Why do you think that is?',
    audioAsset: 'q10.mp3',
    duration: 3.9,
    part: 3,
    transcript: 'Most people tend to ignore or mute adverts because they find them intrusive and repetitive. In the digital age, viewers are accustomed to on-demand content, so they view traditional commercial breaks as an unnecessary disruption to their viewing experience.',
  },
  {
    question: 'How important are regulations on TV advertising?',
    audioAsset: 'q11.mp3',
    duration: 2.1,
    part: 3,
    transcript: 'Regulations are essential to ensure that advertising remains ethical and honest. Without these rules, companies might promote harmful products or use misleading information, which could significantly impact the wellbeing and trust of the general public.',
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

const book12Test1Questions: Question[] = [
  // Part 1: Questions 1-4 (Health & Lifestyle)
  {
    question: 'Is it important to you to eat healthy food? [Why/Why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.0,
    part: 1,
    transcript: 'Yes, it is very important to me. I believe that maintaining a balanced diet is the foundation of good health, as it provides the energy I need for my daily activities and helps prevent long-term illnesses. Eating nutritious food makes me feel more focused and physically active throughout the day.',
  },
  {
    question: 'If you catch a cold, what do you do to help you feel better? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 2.5,
    part: 1,
    transcript: 'When I catch a cold, I usually prioritize getting plenty of rest and staying hydrated by drinking herbal teas or warm water. I also try to increase my intake of vitamin C through fresh fruits. If the symptoms persist, I might take over-the-counter medicine to manage the discomfort.',
  },
  {
    question: 'Do you pay attention to public information about health? [Why/Why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.5,
    part: 1,
    transcript: 'I do pay attention to public health information, especially when it comes to seasonal health advice or vaccination campaigns. I think it is essential to stay informed about community health standards to protect not only myself but also those around me. I usually check official government health websites for reliable updates.',
  },
  {
    question: 'What could you do to have a healthier lifestyle?',
    audioAsset: 'q4.mp3',
    duration: 2.2,
    part: 1,
    transcript: 'To have a healthier lifestyle, I could start by incorporating more physical exercise into my daily routine, such as jogging or swimming for thirty minutes. Additionally, I should try to reduce my intake of processed sugars and ensure I get at least seven hours of sleep every night to improve my overall well-being.',
  },

  // Part 2: Question 5 (Cue Card - Waiting)
  {
    question: 'Describe an occasion when you had to wait a long time for someone or something to arrive.',
    audioAsset: 'q5.mp3',
    duration: 4.0,
    part: 2,
    youShouldSay: [
      'who or what you were waiting for',
      'how long you had to wait',
      'why you had to wait a long time',
      'and explain how you felt about waiting a long time.'
    ],
    transcript: 'I remember a time when I had to wait for nearly two hours for a friend at a busy train station. We had planned to meet for lunch, but he got stuck in a massive traffic jam due to a road accident. I spent the time observing the people passing by and reading a book on my phone to stay occupied. Although I felt a bit frustrated initially, I eventually understood that it was beyond his control. When he finally arrived, we were both so hungry that we ended up having a great meal and laughing about the whole ordeal.',
  },

  // Part 3: Questions 6-11 (Discussion - Arriving Early & Patience)
  {
    question: 'In what kinds of situations should people always arrive early?',
    audioAsset: 'q6.mp3',
    duration: 2.8,
    part: 3,
    transcript: 'People should always arrive early for crucial appointments such as job interviews, medical consultations, and international flights. Arriving early allows individuals to complete necessary security checks or administrative paperwork calmly without the stress of missing deadlines.',
  },
  {
    question: 'How important it is to arrive early in your country?',
    audioAsset: 'q7.mp3',
    duration: 2.5,
    part: 3,
    transcript: 'In my country, punctuality is generally highly valued, especially in professional, educational, and official contexts. Being early or on time demonstrates respect for others and professional commitment, though social gatherings tend to have a slightly more relaxed attitude towards timing.',
  },
  {
    question: 'How can modern technology help people to arrive early?',
    audioAsset: 'q8.mp3',
    duration: 3.1,
    part: 3,
    transcript: 'Modern technology assists people in staying punctual through real-time GPS navigation apps like Google Maps, which calculate optimal routes and warn about traffic congestion. Additionally, digital calendars send automatic reminders and push notifications to help users manage their schedules effectively.',
  },
  {
    question: 'What kinds of jobs require the most patience?',
    audioAsset: 'q9.mp3',
    duration: 2.7,
    part: 3,
    transcript: 'Jobs in healthcare, teaching, and customer service require an immense amount of patience. Medical professionals and educators regularly deal with challenging individuals and complex situations, where maintaining composure and active listening is essential for providing effective care and guidance.',
  },
  {
    question: 'Is it always better to be patient in work (or studies)?',
    audioAsset: 'q10.mp3',
    duration: 3.3,
    part: 3,
    transcript: 'While patience is generally a virtue that fosters thoroughness and high-quality results, there are times when quick decision-making and urgency are necessary. In fast-paced business environments or emergency situations, excessive patience can lead to missed opportunities or delays.',
  },
  {
    question: 'Do you agree or disagree that the older people are, the more patient they are?',
    audioAsset: 'q11.mp3',
    duration: 3.6,
    part: 3,
    transcript: "I generally agree that older people tend to be more patient because life experience teaches them to handle unexpected delays with greater emotional maturity. However, patience also depends on an individual's personality traits and health condition rather than age alone.",
  },
];

const book12Test2Questions: Question[] = [
  // Part 1: Questions 1-4 (Singing & Songs)
  {
    question: 'Did you enjoy singing when you were younger? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.0,
    part: 1,
    transcript: 'Yes, I actually loved singing when I was a child. I used to participate in my school choir and it was a great way for me to express myself. I found it incredibly joyful, especially when learning new melodies with my friends.',
  },
  {
    question: 'How often do you sing now? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 1.5,
    part: 1,
    transcript: "I don't sing very often these days, unfortunately. My current schedule is quite demanding with work and studies, so I rarely find the time. However, I sometimes hum along to music when I am commuting or doing household chores.",
  },
  {
    question: 'Do you have a favorite song you like listening to? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.2,
    part: 1,
    transcript: "I do have a favorite song, which is 'Bohemian Rhapsody' by Queen. I really appreciate the complexity of the composition and the vocal harmonies. Every time I listen to it, I discover something new and interesting about the arrangement.",
  },
  {
    question: 'How important is singing in your culture? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.2,
    part: 1,
    transcript: 'Singing is quite significant in my culture as it is deeply tied to our traditional festivals and celebrations. We have many folk songs that tell stories about our history and heritage. It is a vital way for us to maintain our cultural identity.',
  },

  // Part 2: Question 5 (Cue Card - Film/Movie Actor)
  {
    question: 'Describe a film/movie actor from your country who is very popular.',
    audioAsset: 'q5.mp3',
    duration: 3.2,
    part: 2,
    youShouldSay: [
      'who this actor is',
      'what kinds of films/movies he/she acts in',
      "what you know about this actor's life",
      'and explain why this actor is so popular'
    ],
    transcript: "A highly popular actor from my country is Shah Rukh Khan, who is widely regarded as the 'King of Bollywood.' He has an incredible ability to portray diverse characters, ranging from romantic leads to intense, complex roles. His influence extends far beyond the cinema, as he is known for his immense charisma and philanthropic work. Many people admire him not just for his acting talent, but also for his rags-to-riches story, which serves as a great inspiration to millions. He is undoubtedly a cultural icon.",
  },

  // Part 3: Questions 6-11 (Discussion - Films & Theatre)
  {
    question: 'What are the most popular types of films in your country?',
    audioAsset: 'q6.mp3',
    duration: 2.3,
    part: 3,
    transcript: 'In my country, action movies and romantic comedies are the most popular genres. People often flock to cinemas to watch big-budget blockbusters, especially during holiday periods. Additionally, there is a growing interest in local independent films that reflect our culture.',
  },
  {
    question: 'What is the difference between watching a film in the cinema and watching a film at home?',
    audioAsset: 'q7.mp3',
    duration: 4.5,
    part: 3,
    transcript: 'The main difference is the atmosphere and the immersion. In a cinema, the large screen and high-quality sound system provide an unparalleled experience, whereas watching at home offers comfort and convenience. At home, you can pause or snack, but you lose the shared excitement of a crowd.',
  },
  {
    question: 'Do you think cinemas will close in the future?',
    audioAsset: 'q8.mp3',
    duration: 2.0,
    part: 3,
    transcript: 'I do not believe cinemas will disappear entirely. While streaming services are very convenient, the cinema offers a unique social experience that cannot be replicated at home. As long as people value the collective experience of watching a film on a massive screen, cinemas will remain relevant.',
  },
  {
    question: 'How important is the theatre in your country\'s history?',
    audioAsset: 'q9.mp3',
    duration: 2.3,
    part: 3,
    transcript: "The theatre is deeply rooted in our country's history as a primary form of storytelling and public entertainment. For centuries, it has served as a platform for cultural expression and social commentary. It remains a significant part of our national heritage and identity.",
  },
  {
    question: 'How strong a tradition is it today in your country to go to the theater?',
    audioAsset: 'q10.mp3',
    duration: 2.8,
    part: 3,
    transcript: 'Going to the theatre is still a strong tradition, particularly among the older generation and those in urban areas. While younger people have many digital entertainment options, the theatre is still viewed as a special, high-culture event. It is often a popular choice for celebrations and formal outings.',
  },
  {
    question: 'Do you think the theatre should be run as a business or as a public service?',
    audioAsset: 'q11.mp3',
    duration: 3.9,
    part: 3,
    transcript: 'I believe the theatre should be supported as a public service. While it must be managed efficiently, relying solely on profit can lead to a decline in artistic quality and accessibility. Government funding or arts grants are essential to ensure that theatre remains inclusive and culturally diverse.',
  },
];

const book12Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Clothes)
  {
    question: 'Where do you buy most of your clothes? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 1.4,
    part: 1,
    transcript: 'I generally prefer shopping at local boutique stores in the city center. I enjoy this because the quality is much higher than high-street brands, and the styles are more unique and suited to my personal taste.',
  },
  {
    question: 'How often do you buy new clothes for yourself? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 1.8,
    part: 1,
    transcript: 'I tend to purchase new clothes every few months, usually at the start of each season. This allows me to keep my wardrobe updated with appropriate attire for the changing weather conditions.',
  },
  {
    question: 'How do you decide which clothes to buy? [Why?]',
    audioAsset: 'q3.mp3',
    duration: 1.6,
    part: 1,
    transcript: 'When deciding what to buy, I prioritize the fabric quality and the versatility of the item. I prefer to invest in classic, durable pieces that I can easily mix and match with my existing wardrobe, rather than following fast-fashion trends.',
  },
  {
    question: 'Have the kinds of clothes you like changed in recent years? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 2.6,
    part: 1,
    transcript: 'Yes, my preferences have shifted significantly over the last few years. I used to favor trendy, colorful outfits, but now I gravitate toward a more minimalist style with neutral colors because I find it much more professional and timeless.',
  },

  // Part 2: Question 5 (Cue Card - Interesting Discussion About Money)
  {
    question: 'Describe an interesting discussion you had about how you spend your money.',
    audioAsset: 'q5.mp3',
    duration: 3.4,
    part: 2,
    youShouldSay: [
      'who you had the discussion with',
      'why you discussed this topic',
      'what the result of the discussion was',
      'and explain why this discussion was interesting for you'
    ],
    transcript: 'I recall an interesting discussion I had with my father regarding my monthly budget. We were debating the merits of saving versus investing in stocks. He argued that I should prioritize long-term wealth, while I felt that spending on experiences was more valuable for my personal growth. The conversation was quite eye-opening because it forced me to reconsider my financial priorities and look at money as a tool for future security rather than just immediate consumption.',
  },

  // Part 3: Questions 6-11 (Discussion - Free Time & Work-Life Balance)
  {
    question: 'How do people in your country usually spend their free time?',
    audioAsset: 'q6.mp3',
    duration: 2.9,
    part: 3,
    transcript: 'In my country, people engage in a variety of leisure activities depending on their age and personal interests. Many enjoy socializing with family and friends at restaurants or local parks, while others prefer outdoor sports, watching movies, or engaging in creative hobbies at home.',
  },
  {
    question: 'Is it important for people to have free time? [Why/why not?]',
    audioAsset: 'q7.mp3',
    duration: 3.1,
    part: 3,
    transcript: 'Having adequate free time is vital for maintaining physical and mental health. It allows individuals to recover from daily work stress, pursue personal passions, and spend quality time with loved ones, which ultimately enhances overall productivity and life satisfaction.',
  },
  {
    question: 'Do men and women spend their free time differently?',
    audioAsset: 'q8.mp3',
    duration: 3.0,
    part: 3,
    transcript: 'While individual preferences vary greatly, there can be general differences in how men and women spend their free time. Men often participate more in competitive sports or gaming, whereas women may engage more in creative pursuits, shopping, or group social activities.',
  },
  {
    question: 'What are the main differences between leisure activities today and in the past?',
    audioAsset: 'q9.mp3',
    duration: 3.4,
    part: 3,
    transcript: 'The primary difference lies in the integration of modern digital technology. Today, many leisure activities revolve around screens, such as online streaming and social media, whereas in the past, people relied much more on physical, outdoor, and face-to-face community activities.',
  },
  {
    question: 'Do you think people will have more free time in the future?',
    audioAsset: 'q10.mp3',
    duration: 4.3,
    part: 3,
    transcript: 'With advancements in automation and artificial intelligence, routine tasks may take less time, potentially freeing up more leisure time. However, the blurring boundaries between work and personal life in our connected world could mean that people remain just as busy.',
  },
  {
    question: 'How can people achieve a better work-life balance?',
    audioAsset: 'q11.mp3',
    duration: 2.7,
    part: 3,
    transcript: 'Achieving a good work-life balance requires setting clear professional boundaries and prioritizing personal well-being. Individuals should learn to manage their time effectively, disconnect from digital work channels outside office hours, and dedicate quality time to family and rest.',
  },
];

const book12Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (Art)
  {
    question: 'Did you enjoy doing art lessons when you were a child [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.5,
    part: 1,
    transcript:
      'To be honest, I didn\'t particularly enjoy art lessons as a child. I found it quite frustrating because I felt I lacked the natural creativity required to draw well, and I often struggled to follow the teacher\'s instructions. As a result, I usually felt quite discouraged whenever we had an art project to complete.',
  },
  {
    question: 'Do you ever draw or paint pictures now? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 1.9,
    part: 1,
    transcript:
      'Not really, I rarely draw or paint these days. My current lifestyle is quite hectic, so I prefer to spend my limited free time on activities like reading or exercising. I suppose I simply lost interest in artistic hobbies as I grew older and focused more on my academic studies.',
  },
  {
    question: 'When was the last time you went to an art gallery or exhibition? [Why?]',
    audioAsset: 'q3.mp3',
    duration: 2.7,
    part: 1,
    transcript:
      'It has been quite a long time, actually. I think the last time I visited an art gallery was about three years ago when I was on vacation in Europe. I went there primarily to see some historical paintings, which I found surprisingly fascinating even though I am not an artist myself.',
  },
  {
    question: 'What kind of pictures do you like having in your home? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.2,
    part: 1,
    transcript:
      'I generally prefer to have landscape photography or minimalist prints in my home. I find that these kinds of pictures create a calm and relaxing atmosphere, which is exactly what I want in my living space. I tend to avoid overly complex or abstract art because I find it a bit distracting.',
  },

  // Part 2: Question 5 (Cue Card - Visiting Workplace)
  {
    question:
      'Describe a time when you visited a friend or family member at their workplace.',
    audioAsset: 'q5.mp3',
    duration: 3.7,
    part: 2,
    youShouldSay: [
      'who you visited',
      'where this person worked',
      'why you visited this person\'s workplace',
      'and explain how you felt about visiting this person\'s workplace',
    ],
    transcript:
      'I remember a time when I visited my brother at his architecture firm. It was quite an eye-opening experience to see him in his professional environment, surrounded by blueprints and complex 3D models. The office had a very creative atmosphere, with everyone collaborating intensely on a new city project. I was particularly impressed by how he managed to balance his artistic vision with the strict technical requirements of the buildings. We ended up grabbing a quick lunch together nearby, where he told me more about the challenges of sustainable design.',
  },

  // Part 3: Questions 6-11 (Workplace & Work Environment)
  {
    question: 'What things make an office comfortable to work in?',
    audioAsset: 'q6.mp3',
    duration: 2.3,
    part: 3,
    transcript:
      'A comfortable office environment is primarily defined by ergonomics and atmosphere. Good lighting, comfortable furniture, and a quiet space are essential for maintaining focus. Furthermore, having access to modern technology and a pleasant break area can significantly boost employee morale and productivity.',
  },
  {
    question: 'Why do some people prefer to work outdoors?',
    audioAsset: 'q7.mp3',
    duration: 2.0,
    part: 3,
    transcript:
      'Some individuals prefer working outdoors because they find the natural environment less restrictive than a traditional office. It can provide a sense of freedom, fresh air, and a change of scenery that helps reduce stress. For many, being close to nature improves their creativity and mental well-being.',
  },
  {
    question:
      'Do you agree that the building people work in is more important than the colleagues they work with?',
    audioAsset: 'q8.mp3',
    duration: 4.7,
    part: 3,
    transcript:
      'I believe that the people you work with are actually more important than the physical building. A supportive and collaborative team can make even a substandard workspace feel productive and enjoyable. Conversely, a beautiful office cannot compensate for a toxic or uncooperative work environment.',
  },
  {
    question: 'What would life be like if people didn\'t have to work?',
    audioAsset: 'q9.mp3',
    duration: 2.7,
    part: 3,
    transcript:
      'If people did not have to work, society would likely undergo a massive transformation. Many would dedicate their time to creative pursuits, hobbies, or community service, which could lead to a cultural renaissance. However, it might also lead to a lack of structure and purpose for many, potentially causing widespread boredom or societal instability.',
  },
  {
    question: 'Are all jobs of equal important?',
    audioAsset: 'q10.mp3',
    duration: 1.6,
    part: 3,
    transcript:
      'I do not believe all jobs are of equal importance in terms of societal impact. While every legitimate occupation contributes to the economy, roles in healthcare, emergency services, and education directly preserve life and shape the future of society. Therefore, these essential professions hold a higher level of critical significance.',
  },
  {
    question: 'Why do some people become workaholics?',
    audioAsset: 'q11.mp3',
    duration: 1.7,
    part: 3,
    transcript:
      'Some people become workaholics due to high personal ambition, financial pressure, or a deep passion for their career. For others, work serves as an escape from personal issues or a primary source of self-worth and validation. In highly competitive corporate environments, excessive working hours are often culturally normalized and rewarded.',
  },
];

const book13Test1Questions: Question[] = [
  // Part 1: Questions 1-4 (Television Programmes)
  {
    question: 'Where do you usually watch TV programmes/shows? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.44,
    part: 1,
    transcript: 'I usually watch television programmes in my living room because it is the most comfortable place in my house. My family often gathers there in the evening, which makes the experience more enjoyable. Sometimes, I also watch shows on my laptop in my bedroom if I want to have a private viewing experience.',
  },
  {
    question: "What's your favorite TV programme/show? [Why?]",
    audioAsset: 'q2.mp3',
    duration: 1.95,
    part: 1,
    transcript: 'My absolute favourite programme is a historical documentary series because I find learning about the past fascinating. I love how they use high-quality footage and expert interviews to bring history to life. It is not only entertaining but also very educational, which is Why I never miss an episode.',
  },
  {
    question: 'Are there any programmes/shows you don\'t like watching? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 3.65,
    part: 1,
    transcript: 'I honestly do not like watching reality television shows because I find them quite artificial and repetitive. The drama in those programmes often feels staged rather than genuine, which makes it hard for me to stay interested. I much prefer scripted series or documentaries that offer more substance.',
  },
  {
    question: 'Do you think you will watch more TV or fewer TV programmes/shows in the future? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 3.52,
    part: 1,
    transcript: 'I think I will watch fewer television programmes in the future because I am becoming increasingly busy with my professional development. As my career progresses, I find that I have less leisure time to spend in front of a screen. I would rather spend my limited free time reading books or pursuing outdoor hobbies.',
  },

  // Part 2: Question 5 (Cue Card - Business Start-up)
  {
    question: 'Describe someone you know who has started a business.',
    audioAsset: 'q5.mp3',
    duration: 2.32,
    part: 2,
    youShouldSay: [
      'who this person is',
      'what work this person does',
      'why this person decided to start a business',
      'and explain whether you would like to do the same kind of work as this person.'
    ],
    transcript: 'I would like to talk about my close friend, Sarah, who recently launched a sustainable clothing business. She decided to start this venture because she is deeply passionate about environmental conservation and noticed a lack of eco-friendly options in our local market. She spent months researching ethical suppliers and building her brand identity from scratch. It was truly inspiring to watch her navigate the challenges of entrepreneurship, such as managing finances and marketing, while staying true to her values. Today, her business is thriving and has gained a loyal customer base who appreciate her commitment to sustainability.',
  },

  // Part 3: Questions 6-11 (Discussion - Choosing Work & Work-Life Balance)
  {
    question: 'What kinds of jobs do young people not want to do in your country?',
    audioAsset: 'q6.mp3',
    duration: 2.56,
    part: 3,
    transcript: 'In my country, many young people tend to avoid manual labor or jobs that are perceived as having low social status. Positions in agriculture or factory work are often viewed as less desirable compared to modern office-based roles in technology or finance. There is a strong preference for careers that offer perceived prestige and higher starting salaries.',
  },
  {
    question: 'Who is best at advising young people about choosing a job: teachers or parents?',
    audioAsset: 'q7.mp3',
    duration: 3.66,
    part: 3,
    transcript: 'I believe parents are often better equipped to advise because they understand their child\'s personality and long-term goals deeply. However, teachers can provide more objective information about the current job market and necessary academic qualifications. Ideally, a combination of both perspectives provides the most balanced guidance for a young person.',
  },
  {
    question: 'Is money always the most important thing when choosing a job?',
    audioAsset: 'q8.mp3',
    duration: 3.26,
    part: 3,
    transcript: 'Money is certainly a significant factor, but it is rarely the only one. Many young professionals prioritize job satisfaction, work-life balance, and opportunities for personal growth over a high salary alone. If a job pays well but leads to burnout or unhappiness, it is rarely considered a sustainable or successful career choice.',
  },
  {
    question: 'Do you agree that many people nowadays are under pressure to work longer hours and take less holiday?',
    audioAsset: 'q9.mp3',
    duration: 5.30,
    part: 3,
    transcript: 'Yes, I completely agree. In our competitive culture, there is a prevailing expectation to prioritize productivity over personal time. Many employees feel that working long hours is the only way to prove their commitment or secure a promotion, which unfortunately leads to the erosion of holiday time and leisure.',
  },
  {
    question: 'What is the impact on society of people having a poor working-life balance?',
    audioAsset: 'q10.mp3',
    duration: 3.37,
    part: 3,
    transcript: 'The impact is quite severe, often manifesting as increased stress, mental health issues, and reduced productivity in the long run. When society prioritizes constant work, family relationships can suffer, and the overall quality of life declines. This can lead to a less healthy and less creative workforce, which negatively affects the economy.',
  },
  {
    question: 'Could you recommend some effective strategies for governments and employers to ensure people have a good work-life balance?',
    audioAsset: 'q11.mp3',
    duration: 6.41,
    part: 3,
    transcript: 'Governments should implement stricter labor laws that limit maximum working hours and enforce mandatory rest periods. Meanwhile, employers could offer flexible working arrangements, such as remote work or a four-day work week. Encouraging a culture that values output over hours spent at a desk is the most effective strategy for improvement.',
  },
];

const book13Test2Questions: Question[] = [
  // Part 1: Questions 1-4 (Age)
  {
    question: 'Are you happy to be the age you are now? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.10,
    part: 1,
    transcript: 'I am quite happy with my current age. I feel that I have reached a stage in my life where I am more mature and independent, which allows me to make better decisions for my future. It is a very productive period for my personal and professional growth.',
  },
  {
    question: 'When you were a child, did you think a lot about your future? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.80,
    part: 1,
    transcript: 'Actually, I didn\'t spend much time thinking about the future when I was a child. Back then, I was mostly focused on playing with my friends and enjoying my school days. I think that is quite normal for a child, as the future felt like a very distant and abstract concept.',
  },
  {
    question: 'Do you think you have changed as you have got older? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.45,
    part: 1,
    transcript: 'I believe I have changed significantly as I have grown older. My perspective on life has become more grounded, and I have learned to prioritize what is truly important to me. I am definitely more patient and thoughtful than I was a few years ago.',
  },
  {
    question: 'What will be different about your life in the future? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 2.15,
    part: 1,
    transcript: 'I believe my life will be quite different because I plan to pursue a career in a new field. I expect to have more responsibilities and perhaps live in a different city, which will provide me with new challenges. I am looking forward to these changes as they will help me evolve as a person.',
  },

  // Part 2: Question 5 (Cue Card - Technological Device)
  {
    question: 'Describe a time when you started using a new technological device (e.g. a new computer or phone).',
    audioAsset: 'q5.mp3',
    duration: 5.50,
    part: 2,
    youShouldSay: [
      'what device you started using',
      'why you started using this device',
      'how easy or difficult it was to use',
      'and explain how helpful this device was to you.'
    ],
    transcript: 'Last year, I decided to upgrade to a high-end smartphone because my old device was becoming incredibly slow and unreliable. When I first unboxed the new phone, I was immediately impressed by the sleek design and the vibrant display quality. However, the transition was initially challenging because the operating system had several new features that I wasn\'t familiar with. I spent the entire weekend exploring the settings, customizing the interface, and migrating my data from the old device. Eventually, I grew comfortable with the device, and it has since significantly improved my daily productivity.',
  },

  // Part 3: Questions 6-11 (Discussion - Technology and Education / Society)
  {
    question: 'What is the best age for children to start computer lessons?',
    audioAsset: 'q6.mp3',
    duration: 3.05,
    part: 3,
    transcript: 'I believe the ideal age is around seven or eight. At this stage, children have developed basic literacy and logical thinking skills, which makes it easier for them to grasp the fundamentals of coding and computer navigation without becoming overwhelmed.',
  },
  {
    question: 'Do you think that schools should use more technology to help children learn?',
    audioAsset: 'q7.mp3',
    duration: 4.25,
    part: 3,
    transcript: 'Absolutely. Integrating technology into the classroom can significantly enhance engagement and provide students with access to a wealth of information. It prepares them for a future where digital literacy is an essential skill for almost any career path.',
  },
  {
    question: 'Do you agree or disagree that computers will replace teachers one day?',
    audioAsset: 'q8.mp3',
    duration: 3.45,
    part: 3,
    transcript: 'I strongly disagree with that notion. While computers are excellent at delivering information, they lack the emotional intelligence and ability to mentor students. A teacher\'s role involves fostering critical thinking and providing moral support, which technology simply cannot replicate.',
  },
  {
    question: 'How much has technology improved how we communicate with each other?',
    audioAsset: 'q9.mp3',
    duration: 3.00,
    part: 3,
    transcript: 'Technology has revolutionized communication by making it instantaneous and global. We can now connect with anyone across the world via video calls or messaging apps, which has effectively bridged the geographical divide that once limited our social and professional interactions.',
  },
  {
    question: 'Do you agree that there are still many more major technological innovations to be made?',
    audioAsset: 'q10.mp3',
    duration: 4.40,
    part: 3,
    transcript: 'I do. We are currently seeing rapid developments in fields like artificial intelligence, biotechnology, and renewable energy. These sectors are still in their infancy, and I believe we will witness breakthroughs that will fundamentally change how we live and work.',
  },
  {
    question: 'Could you suggest some reasons why some people are deciding to reduce their use of technology?',
    audioAsset: 'q11.mp3',
    duration: 5.45,
    part: 3,
    transcript: 'Some people are choosing a \'digital detox\' because they feel overwhelmed by constant connectivity. They often find that reducing technology use helps them improve their mental health, regain focus on physical tasks, and spend more quality time with family and friends.',
  },
];

const book13Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Money)
  {
    question: 'When you go shopping, do you prefer to pay for things in cash or by card? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 3.89,
    part: 1,
    transcript: 'I generally prefer to pay by card because it is much more convenient and hygienic than carrying physical cash. It also allows me to keep a digital record of my spending, which helps me manage my monthly budget more effectively.',
  },
  {
    question: 'Do you ever save money to buy special things? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.35,
    part: 1,
    transcript: 'Yes, I frequently save money to purchase special items, such as high-quality electronics or travel experiences. I believe that saving up for a specific goal makes the final purchase feel much more rewarding and prevents me from overspending on impulse items.',
  },
  {
    question: 'Would you ever take a job which had low pay? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.38,
    part: 1,
    transcript: 'I would consider taking a job with low pay only if it offered significant opportunities for gaining practical experience, developing critical skills, or working for an organization whose mission I deeply respect, even though adequate pay remains important.',
  },
  {
    question: 'Would winning a lot of money make a big difference to your life? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 2.59,
    part: 1,
    transcript: 'Yes, winning a substantial sum of money would definitely transform my circumstances. It would provide the freedom to invest in my education and support my family, which would alleviate a great deal of stress.',
  },

  // Part 2: Question 5 (Cue Card - Interesting Discussion)
  {
    question: 'Describe an interesting discussion you had as part of your work or studies.',
    audioAsset: 'q5.mp3',
    duration: 3.63,
    part: 2,
    youShouldSay: [
      'what the subject of the discussion was',
      'who you discussed the subject with',
      'what opinions were expressed',
      'and explain why you found the discussion interesting.'
    ],
    transcript: 'During my final year of university, I had a fascinating discussion with my professor regarding the future of artificial intelligence in education. We debated whether digital tools could truly replace human mentorship. It was an incredibly thought-provoking conversation because it forced me to consider the ethical implications of technology. We explored various case studies, and the exchange of ideas helped me refine my own thesis. Ultimately, it was a memorable experience that significantly shaped my perspective on my future career path.',
  },

  // Part 3: Questions 6-11 (Discussion - Discussing Problems & Communication Skills)
  {
    question: 'Why is it good to discuss problems with other people?',
    audioAsset: 'q6.mp3',
    duration: 2.69,
    part: 3,
    transcript: 'Discussing problems with others is highly beneficial because it allows us to gain a fresh perspective on a situation. Often, when we are stressed, we struggle to see a clear path forward, but a friend might offer a solution we hadn\'t considered. Furthermore, simply verbalizing our worries can act as an emotional release, significantly reducing our anxiety levels.',
  },
  {
    question: 'Do you think that it\'s better to talk to friends and not family about problems?',
    audioAsset: 'q7.mp3',
    duration: 3.74,
    part: 3,
    transcript: 'I believe it depends on the nature of the problem. Friends are often better for social or personal issues because they can offer objective advice without the emotional baggage that family members might have. However, family is usually more supportive when it comes to long-term life decisions or serious crises, as they have a deeper understanding of your history and values.',
  },
  {
    question: 'Is it always a good idea to tell lots of people about a problem?',
    audioAsset: 'q8.mp3',
    duration: 4.05,
    part: 3,
    transcript: 'I don\'t think that is a good idea. Sharing personal problems with too many people can lead to rumors or unwanted judgment, which might make the situation worse. It is much better to be selective and only speak to a small circle of trusted individuals who you know have your best interests at heart.',
  },
  {
    question: 'Which communication skills are most important when taking part in meetings with colleagues?',
    audioAsset: 'q9.mp3',
    duration: 4.73,
    part: 3,
    transcript: 'In meetings, active listening is perhaps the most critical skill, as it ensures you fully understand the points being made by your colleagues. Additionally, being able to articulate your ideas clearly and concisely is essential to avoid misunderstandings. Finally, demonstrating diplomacy and respect when disagreeing with someone helps maintain a productive professional environment.',
  },
  {
    question: 'What are the possible effects of poor written communication skills at work?',
    audioAsset: 'q10.mp3',
    duration: 3.50,
    part: 3,
    transcript: 'Poor written communication can lead to significant confusion and delays in project completion, as instructions might be misinterpreted. It can also damage a person\'s professional reputation, making them appear less competent or disorganized to management. In the long run, it can hinder career progression because effective documentation is vital for most modern roles.',
  },
  {
    question: 'What do you think will be the future impact of technology on communication in the workplace?',
    audioAsset: 'q11.mp3',
    duration: 4.65,
    part: 3,
    transcript: 'Technology will likely continue to make communication more instantaneous, but it may also lead to a decrease in face-to-face interaction. While tools like video conferencing allow for global collaboration, there is a risk that we will lose the nuances of body language and tone. Ultimately, I think the workplace will become more flexible, but we will have to work harder to maintain genuine human connections.',
  },
];

const book13Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (Animals & Birds)
  {
    question: 'Are there many animals or birds where you live? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.30,
    part: 1,
    transcript: 'Actually, there are quite a few birds in my neighborhood, especially in the local park nearby. I often see pigeons and sparrows early in the morning. I enjoy having them around because their singing makes the environment feel much more peaceful and natural.',
  },
  {
    question: 'How often do you watch programmes or read articles about wild animals? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 3.80,
    part: 1,
    transcript: 'I rarely watch programs about wild animals, to be honest. I tend to prefer watching documentaries about history or science instead. However, if a high-quality nature film comes out, I might watch it occasionally to learn more about different ecosystems.',
  },
  {
    question: 'Have you ever been to a zoo or a wildlife park? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.25,
    part: 1,
    transcript: 'Yes, I have visited a large wildlife park a few times when I was younger. It was an interesting experience to see animals like lions and giraffes in a semi-natural habitat. I think it is a great way for people, especially children, to learn about conservation.',
  },
  {
    question: 'Would you like to have a job working with animals? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.85,
    part: 1,
    transcript: 'I don\'t think I would want a career working with animals. While I find them fascinating, I am not trained in biology or veterinary medicine. I believe I am much better suited for a role in an office environment where I can use my organizational skills.',
  },

  // Part 2: Question 5 (Cue Card - Useful Website)
  {
    question: 'Describe a website you use that helps you a lot in your work or studies.',
    audioAsset: 'q5.mp3',
    duration: 3.35,
    part: 2,
    youShouldSay: [
      'what the website is',
      'how often you use the website',
      'what information the website gives you',
      'and explain how your work or studies would change if this website didn\'t exist.'
    ],
    transcript: 'One website that I rely on heavily for my studies is Google Scholar. It is an incredibly powerful search engine specifically designed for academic literature, including articles, theses, and books. I use it almost daily to find credible sources for my research papers and to stay updated with the latest findings in my field. What I find most helpful is the ability to filter results by date and relevance, which saves me a significant amount of time. Furthermore, the \'cite\' feature allows me to generate references in various formats instantly, which is a huge convenience when I am writing long essays.',
  },

  // Part 3: Questions 6-11 (Discussion - The Internet & Social Media)
  {
    question: 'Why do some people find the internet addictive?',
    audioAsset: 'q6.mp3',
    duration: 1.85,
    part: 3,
    transcript: 'Some people find the internet addictive because it offers an endless stream of personalized entertainment and social validation. The constant notifications from social media trigger dopamine releases, which keep users compulsively checking their devices. Furthermore, the internet provides a sense of escapism from daily stresses, making it difficult for some individuals to disconnect.',
  },
  {
    question: 'What would the world be like without the internet?',
    audioAsset: 'q7.mp3',
    duration: 1.60,
    part: 3,
    transcript: 'Life without the internet would be significantly slower and more localized. Communication would rely heavily on traditional methods like physical mail or landline telephones, which would reduce the speed of global business. However, it might also lead to more face-to-face social interactions and a decrease in the digital distractions that currently fragment our attention spans.',
  },
  {
    question: 'Do you think that the way people use the internet may change in the future?',
    audioAsset: 'q8.mp3',
    duration: 4.20,
    part: 3,
    transcript: 'Yes, I believe the way we use the internet will evolve toward more immersive experiences, such as the integration of augmented and virtual reality. As technology advances, the internet will likely become even more deeply embedded in our daily infrastructure, such as through smart homes and the Internet of Things. We will move from simply \'browsing\' content to living within interconnected digital environments.',
  },
  {
    question: 'What are the ways that social media can be used for positive purposes?',
    audioAsset: 'q9.mp3',
    duration: 2.70,
    part: 3,
    transcript: 'Social media can be a powerful tool for social good when used to raise awareness for charitable causes or humanitarian crises. It allows communities to organize, share resources, and mobilize support much faster than traditional media. Additionally, it provides a platform for education, where experts can share knowledge and help people develop new skills regardless of their geographic location.',
  },
  {
    question: 'Why do some individuals post highly negative comments about other people on social media?',
    audioAsset: 'q10.mp3',
    duration: 4.75,
    part: 3,
    transcript: 'Individuals often post negative comments due to the anonymity provided by the internet, which reduces their sense of accountability. This \'online disinhibition effect\' allows people to express aggression they would likely suppress in person. Some also seek attention or validation from like-minded groups by targeting others, turning negativity into a form of social currency within certain online subcultures.',
  },
  {
    question: 'Do you think that companies\' main form of advertising will be via social media in the future?',
    audioAsset: 'q11.mp3',
    duration: 4.80,
    part: 3,
    transcript: 'I believe social media will certainly become a dominant, if not the primary, form of advertising for most companies. Its ability to provide hyper-targeted ads based on user behavior and preferences is far more cost-effective than traditional media like television or print. As algorithms become more sophisticated, companies will increasingly rely on social platforms to convert engagement directly into sales.',
  },
];

const book14Test1Questions: Question[] = [
  // Part 1: Questions 1-4 (Future Plans & Career)
  {
    question: 'What job would you like to have ten years from now? [Why?]',
    audioAsset: 'q1.mp3',
    duration: 2.30,
    part: 1,
    transcript:
      'In ten years, I aspire to be working as a senior project manager in an international firm. I have always been passionate about leadership and coordinating complex tasks, so this role would allow me to utilize my organizational skills effectively. Furthermore, I hope this position will provide me with the financial stability to pursue my personal interests, such as traveling and volunteering.',
  },
  {
    question: 'How useful will English be for your future? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.25,
    part: 1,
    transcript:
      'English will be incredibly useful for my future because it is the global lingua franca of business and technology. Being proficient in English will grant me access to a wider range of career opportunities and international networking events. Without it, I believe it would be significantly more difficult to collaborate with colleagues from different cultural backgrounds in our globalized economy.',
  },
  {
    question: 'How much travelling do you hope to do in the future? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.61,
    part: 1,
    transcript:
      'I hope to do a substantial amount of travelling in the future, particularly exploring regions with rich histories and diverse cultures like South America and Southeast Asia. Travelling exposes you to different ways of living, fosters personal growth, and broadens your perspective on global issues. Whenever my work schedule and finances permit, I definitely plan to take extended trips to experience new environments firsthand.',
  },
  {
    question: 'How do you think your life will change in the future? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.78,
    part: 1,
    transcript:
      'In the future, I anticipate that my life will become much more structured and focused around long-term personal and professional commitments. As I advance in my career and potentially start a family, my daily priorities will naturally shift toward ensuring stability and financial security. Additionally, with advancements in technology, I expect remote work and digital automation will play a larger role in how I manage my daily routine.',
  },

  // Part 2: Question 5 (Cue Card: Book that Made You Think)
  {
    question: 'Describe a book that you enjoyed reading because you had to think a lot.',
    audioAsset: 'q5.mp3',
    duration: 3.40,
    part: 2,
    youShouldSay: [
      'what this book was',
      'why you decided to read it',
      'what reading this book made you think about',
      'and explain why you enjoyed reading this book.',
    ],
    transcript:
      "One book that truly challenged my way of thinking is '1984' by George Orwell. I found it incredibly thought-provoking because it explores complex themes like surveillance, totalitarianism, and the manipulation of truth. Throughout the story, I had to constantly reflect on how these concepts relate to our modern society and the nature of freedom. It wasn't an easy read, but it forced me to analyze the power of language and political control. By the time I finished the final chapter, I felt I had gained a much deeper understanding of the fragility of democratic institutions.",
  },

  // Part 3: Questions 6-11 (Children's Books & Reading)
  {
    question: "What are the most popular types of children's books in your country?",
    audioAsset: 'q6.mp3',
    duration: 3.13,
    part: 3,
    transcript:
      'In my country, illustrated storybooks for young children are incredibly popular. Additionally, educational books that incorporate interactive elements like pop-ups or textures are highly sought after by parents who want to stimulate their child\'s development.',
  },
  {
    question: 'What are the benefits of parents reading books to their children?',
    audioAsset: 'q7.mp3',
    duration: 2.48,
    part: 3,
    transcript:
      'Reading to children is immensely beneficial as it significantly enhances their vocabulary and language acquisition skills. Moreover, it fosters a strong emotional bond between the parent and the child, creating a comforting routine that encourages a lifelong love of reading.',
  },
  {
    question: 'Should parents always let children choose the books they read?',
    audioAsset: 'q8.mp3',
    duration: 3.00,
    part: 3,
    transcript:
      'While it is important to encourage autonomy, I believe parents should provide some guidance. Children might choose books that are too simple or repetitive, so parents should ensure a balance between the child\'s preferences and age-appropriate, challenging materials.',
  },
  {
    question: 'How popular are electronic books in your country?',
    audioAsset: 'q9.mp3',
    duration: 2.38,
    part: 3,
    transcript:
      'Electronic books have gained significant popularity in my country over the last few years. They are widely used by students and commuters due to their portability and the convenience of having an entire library on a single device.',
  },
  {
    question: 'What are the advantages of parents reading electronic books (compared to printed books)?',
    audioAsset: 'q10.mp3',
    duration: 4.86,
    part: 3,
    transcript:
      'The primary advantage of electronic books is their accessibility and the ability to adjust font sizes or use built-in dictionaries. Furthermore, many e-books for children include interactive features such as animations and audio narration, which can make the reading experience more engaging.',
  },
  {
    question: 'Will electronic books ever completely replace printed books in the future?',
    audioAsset: 'q11.mp3',
    duration: 3.87,
    part: 3,
    transcript:
      'I do not believe they will completely replace printed books. Many people still value the tactile experience of holding a physical book and the lack of digital distractions. I think they will continue to coexist, as each format serves different purposes for different readers.',
  },
];

const book14Test2Questions: Question[] = [
  // Part 1: Questions 1-4 (Social Media)
  {
    question: 'Which social media websites do you use?',
    audioAsset: 'q1.mp3',
    duration: 2.20,
    part: 1,
    transcript:
      "I primarily use Instagram and LinkedIn. I find Instagram to be the most engaging platform for keeping up with friends' updates, while I use LinkedIn to stay informed about professional trends and network with people in my industry.",
  },
  {
    question: 'How much time do you spend on social media sites? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.40,
    part: 1,
    transcript:
      'I would estimate that I spend about an hour each day on social media. I usually check my notifications during my commute and again in the evening, as I believe it is important to limit my screen time to maintain a healthy work-life balance.',
  },
  {
    question: 'What kind of information about yourself have you put on social media? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 3.95,
    part: 1,
    transcript:
      'I am quite cautious about the information I share publicly. I only include basic professional details and a profile picture; I prefer to keep my private life, such as my home address or personal phone number, completely off these platforms for security reasons.',
  },
  {
    question: "Is there anything you don't like about social media? [Why?]",
    audioAsset: 'q4.mp3',
    duration: 2.30,
    part: 1,
    transcript:
      'Yes, there is. I particularly dislike the prevalence of misinformation and the addictive nature of the algorithms. It can be quite overwhelming to see so much negative content, which is why I often take breaks from these apps to focus on my mental well-being.',
  },

  // Part 2: Question 5 (Cue Card - Something bought for home)
  {
    question: 'Describe something you liked very much which you bought for your home.',
    audioAsset: 'q5.mp3',
    duration: 3.40,
    part: 2,
    youShouldSay: [
      'what you bought',
      'when and where you bought it',
      'why you chose this particular thing',
      'and explain why you liked it so much.',
    ],
    transcript:
      'One item I recently purchased for my home that I am particularly fond of is a high-quality ergonomic office chair. I decided to invest in it because I have been working remotely more often and noticed that my old chair was causing back pain. It features adjustable lumbar support and breathable mesh material, which makes a significant difference during long working hours. Not only does it improve my posture, but its sleek, modern design also complements the aesthetics of my home office perfectly. I feel that this was a highly beneficial purchase that combines both comfort and functionality.',
  },

  // Part 3: Questions 6-11 (Discussion - Homes & Accommodation)
  {
    question: 'Why do some people buy lots of things for their home?',
    audioAsset: 'q6.mp3',
    duration: 2.95,
    part: 3,
    transcript:
      "People often invest in their homes to reflect their personal identity and aesthetic preferences. Furthermore, creating a comfortable and organized living space significantly enhances one's psychological well-being and daily productivity.",
  },
  {
    question: 'Do you think it is very expensive to make a home look nice?',
    audioAsset: 'q7.mp3',
    duration: 3.50,
    part: 3,
    transcript:
      'Not necessarily. While high-end interior design can be costly, one can achieve a stylish home on a budget through creative DIY projects, upcycling furniture, or simply decluttering and rearranging existing items.',
  },
  {
    question: "Why don't some people care about how their home looks?",
    audioAsset: 'q8.mp3',
    duration: 2.25,
    part: 3,
    transcript:
      'Some individuals prioritize function over form, viewing a home merely as a place to sleep and eat rather than a space for self-expression. They may also be preoccupied with demanding careers or financial constraints, leaving them little time or energy to focus on interior decor.',
  },
  {
    question: 'In what ways is living in a flat/apartment better than living in a house?',
    audioAsset: 'q9.mp3',
    duration: 4.15,
    part: 3,
    transcript:
      'Apartments are often more advantageous due to their central locations, which reduce commuting time to work or city centers. Additionally, they typically require less maintenance and offer enhanced security features, making them a practical choice for busy professionals or those living alone.',
  },
  {
    question: 'Do you think homes will look different in the future?',
    audioAsset: 'q10.mp3',
    duration: 2.80,
    part: 3,
    transcript:
      'Yes, I believe homes will become increasingly integrated with smart technology, focusing on automation and energy efficiency. We will likely see more sustainable building materials and modular designs that can adapt to the changing needs of the occupants.',
  },
  {
    question: 'Do you agree that the kinds of homes people prefer change as they get older?',
    audioAsset: 'q11.mp3',
    duration: 4.30,
    part: 3,
    transcript:
      'I agree, because our priorities shift as we move through different life stages. For instance, young adults often seek proximity to social hubs, whereas families prioritize space and safety, and older individuals often prefer smaller, more accessible homes that are easier to maintain.',
  },
];

const book14Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Neighbours & Community)
  {
    question: 'How often do you see your neighbours? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 1.65,
    part: 1,
    transcript:
      'I see my neighbours quite frequently, usually once or twice a week. We often bump into each other in the hallway or the communal garden, so we tend to stop and chat for a few minutes to catch up on how things are going.',
  },
  {
    question: 'Do you invite your neighbours to your home? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 1.88,
    part: 1,
    transcript:
      'To be honest, I rarely invite my neighbours over to my home. While we are on friendly terms, I prefer to keep my home as a private space for my close family and friends rather than hosting formal social gatherings with neighbours.',
  },
  {
    question: 'Do you think you are a good neighbour? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 1.41,
    part: 1,
    transcript:
      'I believe I am a considerate neighbour because I always make sure to keep noise levels down, especially late at night. I also respect their privacy and always keep the shared areas of our building clean and tidy.',
  },
  {
    question: 'Has a neighbour ever helped you? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.57,
    part: 1,
    transcript:
      'I remember one instance when I was locked out of my apartment late at night. My neighbour kindly allowed me to use their phone to call a locksmith and even offered me a cup of tea while I waited for help.',
  },

  // Part 2: Question 5 (Cue Card: Difficult Task Succeeded At)
  {
    question: 'Describe a very difficult task that you succeeded in doing as part of your work or studies.',
    audioAsset: 'q5.mp3',
    duration: 4.52,
    part: 2,
    youShouldSay: [
      'what task you did',
      'why this task was very difficult',
      'how you worked on this task',
      'and explain how you felt when you had successfully completed this task.',
    ],
    transcript:
      'A particularly challenging task I faced during my final year of university was completing a comprehensive research project on climate change. The primary difficulty lay in gathering primary data from diverse sources and synthesizing it into a cohesive argument within a very tight deadline. To overcome this, I broke the project into smaller, manageable milestones and dedicated specific hours each day to data analysis. I successfully managed to submit the project two days early, and it ended up receiving the highest grade in my cohort. This experience taught me the importance of time management and persistence when tackling complex professional or academic challenges.',
  },

  // Part 3: Questions 6-11 (Difficult Jobs & Goals)
  {
    question: 'What are the most difficult jobs that people do?',
    audioAsset: 'q6.mp3',
    duration: 1.59,
    part: 3,
    transcript:
      'Jobs that require high levels of physical labor or extreme mental pressure are often considered the most difficult. For example, surgeons face immense stress because they are responsible for human lives, while miners work in dangerous and physically exhausting environments. These roles demand not only specialized skill but also significant emotional resilience.',
  },
  {
    question: 'Why do you think some people choose to do difficult jobs?',
    audioAsset: 'q7.mp3',
    duration: 2.43,
    part: 3,
    transcript:
      'Many people are drawn to challenging careers because of the sense of personal fulfillment and the potential for high status. Others are motivated by the desire to solve complex problems or contribute to society in a meaningful way. Ultimately, the reward of overcoming difficult obstacles often outweighs the stress involved in these positions.',
  },
  {
    question: 'Do you agree or disagree that all jobs are difficult sometimes?',
    audioAsset: 'q8.mp3',
    duration: 2.95,
    part: 3,
    transcript:
      'I would agree with that statement to an extent. Every job has periods of high pressure, whether it involves meeting tight deadlines, managing difficult clients, or dealing with unexpected technical failures. Even routine jobs can become difficult if the environment is stressful or if the worker lacks the necessary support.',
  },
  {
    question: 'How important is it for everyone to have a goal in their personal life?',
    audioAsset: 'q9.mp3',
    duration: 2.77,
    part: 3,
    transcript:
      'Having a personal goal is fundamental to human motivation and direction. Without a goal, individuals often feel stagnant or lose their drive to improve. Goals provide a framework for decision-making and help people prioritize their time, which is essential for personal growth and long-term satisfaction.',
  },
  {
    question: 'Is it always necessary to work hard in order to achieve career success?',
    audioAsset: 'q10.mp3',
    duration: 4.18,
    part: 3,
    transcript:
      'Hard work is certainly a primary factor in career success, but it is not the only one. While dedication and persistence are necessary to master a craft, success also requires networking, adaptability, and sometimes a bit of luck. Relying solely on hard work without a strategy may not always lead to the desired results.',
  },
  {
    question: 'Do you think that successful people are always happy people?',
    audioAsset: 'q11.mp3',
    duration: 3.29,
    part: 3,
    transcript:
      'Not necessarily. While professional success often brings financial stability and recognition, it does not automatically equate to personal happiness. Many successful individuals experience high levels of stress and burnout. True happiness usually stems from a balance between professional achievements and personal well-being, such as healthy relationships and mental health.',
  },
];

const book14Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (Neighbourhood & Living Area)
  {
    question: 'Do you like the neighbourhood you live in? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 1.55,
    part: 1,
    transcript:
      'Actually, I quite enjoy living in my neighbourhood. It is a very peaceful area with plenty of green spaces, which makes it perfect for relaxing after a long day of work. The community is very friendly, and I feel quite safe here, which is the most important thing for me.',
  },
  {
    question: 'What do you do in your neighbourhood in your free time? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.30,
    part: 1,
    transcript:
      'In my free time, I usually head to the local park to go for a jog or read a book under the trees. Occasionally, I like to visit the small café on the corner to grab a coffee and catch up with some of my neighbours. It is a great way to stay active and socialise.',
  },
  {
    question: 'What new things would you like to have in your neighbourhood? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.25,
    part: 1,
    transcript:
      'I would love to see a more modern community centre or perhaps a library in our neighbourhood. Currently, we lack a dedicated space for social events or workshops, and I think that would really bring the residents closer together. Improved public transport links would also be a fantastic addition.',
  },
  {
    question: 'Would you like to live in another neighbourhood in your town or city? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 3.75,
    part: 1,
    transcript:
      'While I am happy where I am, I would be open to moving to a more central part of the city. I think living closer to the business district would significantly reduce my daily commute and give me more time to spend on my hobbies. However, I would only move if I could find a place that is just as quiet as my current home.',
  },

  // Part 2: Question 5 (Cue Card: Website Bought From)
  {
    question: 'Describe a website you have bought something from.',
    audioAsset: 'q5.mp3',
    duration: 2.30,
    part: 2,
    youShouldSay: [
      'what the website is',
      'what you bought from this website',
      'how satisfied you were with what you bought',
      'and explain what you liked and disliked about using this website.',
    ],
    transcript:
      'I frequently use Amazon to purchase various items because of its incredible convenience and extensive inventory. Last month, I decided to buy a new ergonomic office chair from their website to improve my posture while working from home. Navigating the site was seamless, as the search filters allowed me to quickly narrow down my options based on price, customer ratings, and material quality. Once I placed the order, the tracking feature kept me informed about the delivery status in real-time, and the package arrived at my doorstep within two days. Overall, I find the website highly reliable and user-friendly, which is why it has become my go-to platform for online shopping.',
  },

  // Part 3: Questions 6-11 (Online Shops, Pricing & Retail Malls)
  {
    question: 'What kinds of things do people in your country often buy from online shops?',
    audioAsset: 'q6.mp3',
    duration: 3.55,
    part: 3,
    transcript:
      'In my country, people frequently purchase electronics, clothing, and household goods online. E-commerce platforms like Shopee and Lazada have become incredibly popular because they offer a wider variety of products than local physical stores.',
  },
  {
    question: 'Why has online shopping become so popular in many countries?',
    audioAsset: 'q7.mp3',
    duration: 2.70,
    part: 3,
    transcript:
      'Online shopping has surged in popularity primarily due to its unparalleled convenience. Consumers can browse and purchase items from the comfort of their homes at any time, often finding better prices and more competitive deals compared to traditional retail outlets.',
  },
  {
    question: 'What are some possible disadvantages of buying things from online shops?',
    audioAsset: 'q8.mp3',
    duration: 4.10,
    part: 3,
    transcript:
      'One major disadvantage is the inability to physically inspect products before purchasing, which can lead to disappointment regarding quality or size. Additionally, there are concerns about data security and the potential for shipping delays or damaged goods during transit.',
  },
  {
    question: 'Do you agree that the prices of all goods should be lower on internet shopping sites than in shops?',
    audioAsset: 'q9.mp3',
    duration: 5.40,
    part: 3,
    transcript:
      'I do not necessarily agree that all goods should be cheaper online. While internet sites often have lower overhead costs, physical shops provide immediate availability and the benefit of personalized customer service, which justifies a different pricing structure for many consumers.',
  },
  {
    question: 'Will large shopping malls continue to be popular, despite the growth of internet shopping?',
    audioAsset: 'q10.mp3',
    duration: 4.50,
    part: 3,
    transcript:
      'I believe large shopping malls will remain relevant but will have to evolve. They are increasingly becoming \'experience centers\' where people go for dining, entertainment, and social interaction, rather than just shopping for necessities, allowing them to coexist with online retail.',
  },
  {
    question: 'Do you think that some businesses (e.g. banks and travel agents) will only operate online in the future?',
    audioAsset: 'q11.mp3',
    duration: 5.35,
    part: 3,
    transcript:
      'It is highly probable that many businesses will shift to an online-only model. Digital transformation allows companies to reduce operational costs significantly while reaching a global audience, making it a logical progression for sectors like banking and travel services.',
  },
];

const book15Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Swimming)
  {
    question: 'Did you learn to swim when you were a child? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.8,
    part: 1,
    transcript:
      'Yes, I did. My parents enrolled me in swimming lessons at a local pool when I was around six years old. They believed it was an essential life skill for safety, especially during family holidays near the water.',
  },
  {
    question: 'How often do you go swimming now? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.5,
    part: 1,
    transcript:
      'Honestly, I don\'t go swimming very often these days, maybe once or twice a month during the summer. Busy work schedules make it hard to visit the pool regularly, so I usually reserve it for recreational outings.',
  },
  {
    question: 'What places are there for swimming where you live? [Why?]',
    audioAsset: 'q3.mp3',
    duration: 2.6,
    part: 1,
    transcript:
      'Where I live, there are a few options, including a public community centre with a heated indoor pool and several private fitness clubs. Additionally, there is a popular public beach nearby that gets very busy in the warm summer months.',
  },
  {
    question:
      'Do you think it would be more enjoyable to go swimming outdoors or at an indoor pool? [Why?]',
    audioAsset: 'q4.mp3',
    duration: 4.2,
    part: 1,
    transcript:
      'I think swimming outdoors is generally more enjoyable because you can experience fresh air and natural sunlight. However, an indoor pool is much more practical year-round, as it isn\'t affected by unpredictable weather or cold temperatures.',
  },

  // Part 2: Question 5 (Cue Card - Famous Business Person)
  {
    question: 'Describe a famous business person that you know about.',
    audioAsset: 'q5.mp3',
    duration: 3.8,
    part: 2,
    youShouldSay: [
      'who this person is',
      'what kind of business this person is involved in',
      'what you know about this business person',
      'and explain what you think of this business person.',
    ],
    transcript:
      'A famous business person I have always admired is Elon Musk. He is well-known for his visionary leadership at companies like Tesla and SpaceX, which are revolutionizing the automotive and aerospace industries. I find his ability to take massive risks on futuristic technology truly inspiring. What impresses me most is his relentless work ethic and his focus on solving global problems, such as sustainable energy and multi-planetary travel. Although he is a controversial figure, there is no denying that his influence on modern business and innovation is significant.',
  },

  // Part 3: Questions 6-11 (Famous People & Fame)
  {
    question: 'What kinds of people are most famous in your country today?',
    audioAsset: 'q6.mp3',
    duration: 2.5,
    part: 3,
    transcript:
      'In my country, the most famous individuals are typically social media influencers and reality television stars. While traditional actors and musicians still hold a significant place in the public eye, digital creators have gained massive followings due to their daily engagement with young audiences.',
  },
  {
    question:
      'Why are there so many stories about famous people in the news?',
    audioAsset: 'q7.mp3',
    duration: 2.4,
    part: 3,
    transcript:
      'The media focuses heavily on famous people because it is highly profitable. Gossip, scandals, and personal details about celebrities generate significant web traffic and advertising revenue, which media outlets rely on to sustain their business models.',
  },
  {
    question:
      'Do you agree or disagree that many young people today want to be famous?',
    audioAsset: 'q8.mp3',
    duration: 2.3,
    part: 3,
    transcript:
      'I believe this is true to a large extent. The rise of platforms like Instagram and TikTok has made fame seem more accessible and desirable than ever before, leading many young people to view \'influencer\' status as a viable and lucrative career path.',
  },
  {
    question:
      'Do you think it is easy for famous people to earn a lot of money?',
    audioAsset: 'q9.mp3',
    duration: 2.8,
    part: 3,
    transcript:
      'It can be, provided they have established a strong personal brand. Once a celebrity reaches a certain level of fame, they can earn substantial income through endorsements, sponsorships, and high-profile appearances, which often pay significantly more than their primary profession.',
  },
  {
    question:
      'Why might famous people enjoy having fans?',
    audioAsset: 'q10.mp3',
    duration: 2.6,
    part: 3,
    transcript:
      'Famous people often enjoy having fans because it provides validation for their work and helps build a sense of community. Furthermore, a dedicated fanbase acts as a powerful support system that can help them promote new projects and maintain their relevance in a competitive industry.',
  },
  {
    question:
      'In what ways could famous people use their influence to do good things in the world?',
    audioAsset: 'q11.mp3',
    duration: 3.2,
    part: 3,
    transcript:
      'Celebrities have the unique ability to draw global attention to critical issues. By leveraging their massive platforms, they can raise funds for charities, advocate for social justice, and influence public policy, thereby creating a positive impact that ordinary citizens might struggle to achieve.',
  },
];

const book16Test3Questions: Question[] = [
  // Part 1: Questions 1-4 (Summer)
  {
    question: 'Is summer your favorite time of year? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.3,
    part: 1,
    transcript:
      'Yes, summer is definitely my favorite time of year. I love the long daylight hours and warm weather, which make it much easier to enjoy outdoor activities like hiking and spending time with friends.',
  },
  {
    question: 'What do you do in summer when the weather\'s very hot? [Why?]',
    audioAsset: 'q2.mp3',
    duration: 2.4,
    part: 1,
    transcript:
      'When the weather gets extremely hot in summer, I usually stay indoors in air-conditioned spaces or go swimming at a local pool. I try to avoid direct sunlight during midday peak hours to stay cool and comfortable.',
  },
  {
    question: 'Do you go on holiday every summer? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 1.7,
    part: 1,
    transcript:
      'I do not go on holiday every single summer. While I enjoy traveling, it can be quite expensive, so I prefer to take a major trip every two years instead of traveling annually.',
  },
  {
    question:
      'Did you enjoy the summer holidays when you were at school? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 2.7,
    part: 1,
    transcript:
      'I absolutely loved the summer holidays when I was at school. It was a wonderful time to relax, meet up with my friends every day, and pursue hobbies that I didn\'t have time for during the busy academic term.',
  },

  // Part 2: Question 5 (Cue Card - Luxury Item)
  {
    question: 'Describe a luxury item you would like to own in the future.',
    audioAsset: 'q5.mp3',
    duration: 3.0,
    part: 2,
    youShouldSay: [
      'what item you would like to own',
      'what this item looks like',
      'why you would like to own this item',
      'and explain whether you think you will ever own this item.',
    ],
    transcript:
      'One luxury item I have always dreamed of owning is a high-end mechanical wristwatch, specifically a Patek Philippe. I have been fascinated by the intricate craftsmanship and the engineering precision required to create such a timeless piece. In the future, once I have established my career, I hope to purchase one as a symbol of my hard work and personal success. Beyond its status, I appreciate it as a piece of art that can be passed down through generations. It is not just about the brand, but about owning a masterpiece of horology.',
  },

  // Part 3: Questions 6-11 (Buying, Expensive Items & Wealth)
  {
    question: 'Which expensive items would many young people (in your country) like to buy?',
    audioAsset: 'q6.mp3',
    duration: 2.8,
    part: 3,
    transcript:
      'In my country, many young people are particularly keen on acquiring high-end electronics, such as the latest smartphones or gaming consoles. Additionally, there is a strong trend toward investing in fashionable branded clothing and sneakers, which are seen as status symbols among peers.',
  },
  {
    question:
      'How do the expensive items that younger people want to buy differ from those that older people want to buy?',
    audioAsset: 'q7.mp3',
    duration: 2.4,
    part: 3,
    transcript:
      'The primary difference lies in priorities. Younger people often gravitate toward items related to lifestyle, entertainment, and social status, whereas older generations tend to prioritize long-term investments, such as home improvements, high-quality furniture, or practical appliances that offer lasting utility.',
  },
  {
    question:
      'Do you think that people are more likely to buy expensive items for their friends or for themselves?',
    audioAsset: 'q8.mp3',
    duration: 3.1,
    part: 3,
    transcript:
      'I think people are generally more likely to purchase expensive items for themselves, as high-priced goods require significant financial consideration. However, people do buy costly gifts for close family or friends on special occasions like weddings or milestone birthdays.',
  },
  {
    question:
      'How difficult is it to become very rich in today\'s world?',
    audioAsset: 'q9.mp3',
    duration: 2.4,
    part: 3,
    transcript:
      'Acquiring wealth in today\'s world is quite challenging due to high economic competition and rising living costs. However, digital platforms and technology have created new entrepreneurial opportunities that allow innovative individuals to build successful businesses faster than in the past.',
  },
  {
    question:
      'Do you agree that money does not necessarily bring happiness?',
    audioAsset: 'q10.mp3',
    duration: 2.7,
    part: 3,
    transcript:
      'I strongly agree with that sentiment. While money can certainly alleviate financial stress and provide access to better healthcare and education, true happiness is derived from personal relationships, health, and a sense of purpose, none of which can be purchased.',
  },
  {
    question:
      'In what ways might rich people use their money to help society?',
    audioAsset: 'q11.mp3',
    duration: 2.4,
    part: 3,
    transcript:
      'Wealthy individuals can make a profound impact by funding philanthropic initiatives, such as medical research, educational scholarships, or environmental conservation projects. Beyond simple donations, they can also invest in social enterprises that create sustainable jobs and support local communities.',
  },
];


const book16Test4Questions: Question[] = [
  // Part 1: Questions 1-4 (Fast Food & Cooking)
  {
    question: 'What kinds of fast food have you tried? [Why/why not?]',
    audioAsset: 'q1.mp3',
    duration: 2.1,
    part: 1,
    transcript:
      'I have tried various types of fast food, such as burgers and fried chicken. I generally enjoy them because they are convenient and flavorful, though I try to limit my intake for health reasons.',
  },
  {
    question: 'Do you ever use a microwave to cook food quickly? [Why/why not?]',
    audioAsset: 'q2.mp3',
    duration: 2.6,
    part: 1,
    transcript:
      'Yes, I frequently use a microwave to reheat leftovers or prepare quick snacks. It is incredibly time-efficient, which is helpful when I have a busy schedule and need to eat something immediately.',
  },
  {
    question: 'How popular are fast food restaurants where you live? [Why/why not?]',
    audioAsset: 'q3.mp3',
    duration: 2.3,
    part: 1,
    transcript:
      'Fast food restaurants are extremely popular in my city, especially among the younger generation. You can find major international chains on almost every street corner because they offer a consistent and affordable dining experience.',
  },
  {
    question: 'When would you go to a fast-food restaurant? [Why/why not?]',
    audioAsset: 'q4.mp3',
    duration: 1.9,
    part: 1,
    transcript:
      'I typically visit a fast-food restaurant when I am traveling or when I am in a rush and do not have time to cook a proper meal at home. It is a practical solution for those moments when I need a quick bite.',
  },

  // Part 2: Question 5 (Cue Card - Technology Stopped Using)
  {
    question:
      'Describe some technology (e.g an app, phone, software program) that you decided to stop using.',
    audioAsset: 'q5.mp3',
    duration: 3.0,
    part: 2,
    youShouldSay: [
      'when and where you got this technology',
      'why you started using this technology',
      'why you decided to stop using it',
      'and explain how you feel about the decision you made.',
    ],
    transcript:
      "A few years ago, I decided to stop using a popular social media app called Snapchat. Initially, I found it fun for sharing quick photos with friends, but eventually, I realized it was becoming a major distraction in my daily life. The constant notifications and the pressure to maintain 'streaks' made me feel anxious and unproductive. I found myself checking the app every few minutes, which really hindered my ability to focus on my university studies. Consequently, I deleted the account permanently, and I have felt much more present and focused ever since.",
  },

  // Part 3: Questions 6-11 (Computer Games & Educational Tech)
  {
    question: 'What kinds of computer games do people play in your country?',
    audioAsset: 'q6.mp3',
    duration: 1.7,
    part: 3,
    transcript:
      'In my country, multiplayer online battle arena games and first-person shooters are immensely popular among young adults. Additionally, casual mobile puzzle games are widely played by people of all ages during their daily commutes.',
  },
  {
    question: 'Why do people enjoy playing computer games?',
    audioAsset: 'q7.mp3',
    duration: 2.1,
    part: 3,
    transcript:
      'People enjoy computer games primarily because they offer an immersive form of entertainment and stress relief. They also provide opportunities for social connection through online multiplayer modes and allow players to solve challenging puzzles.',
  },
  {
    question:
      'Do you think that all computer games should have a minimum age for players?',
    audioAsset: 'q8.mp3',
    duration: 4.0,
    part: 3,
    transcript:
      'Yes, I firmly believe that age ratings are necessary for computer games. Many games feature intense violence, graphic content, or in-game purchases that are unsuitable for young children, so clear age guidelines help parents make informed choices.',
  },
  {
    question: 'In what ways can technology in the classroom be helpful?',
    audioAsset: 'q9.mp3',
    duration: 1.6,
    part: 3,
    transcript:
      'Technology in classrooms enhances learning by providing interactive digital textbooks, educational videos, and instant access to research materials. It also enables teachers to personalize instruction and make lessons more engaging through multimedia presentations.',
  },
  {
    question:
      'Do you agree that students are often better at using technology than their teachers?',
    audioAsset: 'q10.mp3',
    duration: 2.9,
    part: 3,
    transcript:
      'Generally speaking, yes. Younger generations have grown up surrounded by digital devices, making them digital natives who adapt to new apps effortlessly, whereas some older educators may require more formal training to master modern educational tools.',
  },
  {
    question: 'Do you believe that computers will ever replace human teachers?',
    audioAsset: 'q11.mp3',
    duration: 3.0,
    part: 3,
    transcript:
      'No, I do not think computers will ever fully replace human teachers. While artificial intelligence can deliver information efficiently, teachers provide empathy, moral guidance, and emotional support that technology simply cannot replicate.',
  },
];

const testSuites: { [key: string]: Question[] } = {
  'IELTS Book 16 Test 4': book16Test4Questions,
  'IELTS Book 16 Test 3': book16Test3Questions,
  'IELTS Book 15 Test 3': book15Test3Questions,
  'IELTS Book 14 Test 4': book14Test4Questions,
  'IELTS Book 14 Test 3': book14Test3Questions,
  'IELTS Book 14 Test 2': book14Test2Questions,
  'IELTS Book 14 Test 1': book14Test1Questions,
  'IELTS Book 13 Test 4': book13Test4Questions,
  'IELTS Book 13 Test 3': book13Test3Questions,
  'IELTS Book 13 Test 2': book13Test2Questions,
  'IELTS Book 13 Test 1': book13Test1Questions,
  'IELTS Book 12 Test 4': book12Test4Questions,
  'IELTS Book 12 Test 3': book12Test3Questions,
  'IELTS Book 12 Test 2': book12Test2Questions,
  'IELTS Book 12 Test 1': book12Test1Questions,
  'IELTS Book 11 Test 4': book11Test4Questions,
  'IELTS Book 11 Test 3': book11Test3Questions,
  'IELTS Book 11 Test 2': book11Test2Questions,
  'IELTS Book 11 Test 1': book11Test1Questions,
  'IELTS Book 10 Test 4': book10Test4Questions,
  'IELTS Book 10 Test 3': book10Test3Questions,
  'IELTS Book 10 Test 2': book10Test2Questions,
  'IELTS Book 10 Test 1': book10Test1Questions,
  'IELTS Book 21 Test 1': book21Test1Questions,
};

const PASTEL_WAVE_COLORS = [
  '#FCA5A5', '#FCA5A5', '#FCA5A5',
  '#FDBA74', '#FDBA74', '#FDBA74',
  '#FDE047', '#FDE047', '#FDE047',
  '#86EFAC', '#86EFAC', '#86EFAC',
  '#4ADE80', '#4ADE80',
  '#2DD4BF', '#2DD4BF',
  '#38BDF8', '#38BDF8',
  '#60A5FA', '#60A5FA',
  '#818CF8', '#818CF8',
  '#A78BFA', '#A78BFA',
  '#C084FC', '#C084FC',
];

export default function SpeakingPracticePage() {
  const [selectedTestTitle, setSelectedTestTitle] = useState('IELTS Book 10 Test 3');
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

  const [waveformHeights, setWaveformHeights] = useState<number[]>(() =>
    Array.from({ length: 26 }, (_, i) => 6.0 + 14.0 * Math.sin((i / 25.0) * Math.PI))
  );

  useEffect(() => {
    let interval: any = null;
    if (isPlayingAudio || isRecording) {
      interval = setInterval(() => {
        setWaveformHeights(
          Array.from({ length: 26 }, (_, i) => {
            const envelope = Math.sin((i / 25.0) * Math.PI);
            const jitter = Math.random() * 16.0 * (envelope + 0.2);
            return Math.max(6, Math.min(26, 6.0 + jitter));
          })
        );
      }, 120);
    } else {
      setWaveformHeights(
        Array.from({ length: 26 }, (_, i) => 6.0 + 14.0 * Math.sin((i / 25.0) * Math.PI))
      );
    }
    return () => clearInterval(interval);
  }, [isPlayingAudio, isRecording]);

  const playQuestionAudio = () => {
    if (!currentQuestion) return;
    const folderName = selectedTestTitle.replace('Book', 'BOOK').trim();
    const audioUrl = `/audio/speaking/${folderName}/${currentQuestion.audioAsset}`;

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

    const isSingleWordOrMinimal = totalWords <= 5 || (avgWords < 3 && totalWords < 15);

    let band = 1.0;
    if (isSingleWordOrMinimal) {
      if (selectedTestTitle.includes('Book 14 Test 4')) {
        band = selectedPart === 1 ? 1.0 : 0.0;
      } else if (selectedTestTitle.includes('Book 14 Test 2')) {
        band = selectedPart === 1 ? 0.0 : 1.0;
      } else if (selectedTestTitle.includes('Book 13 Test 2')) {
        band = selectedPart === 1 ? 2.0 : 1.0;
      } else {
        band = selectedPart === 3 ? 0.0 : 1.0;
      }
    } else if (totalWords > 60 && avgWords >= 15) {
      band = 7.5;
    } else if (totalWords > 40 && avgWords >= 10) {
      band = 6.5;
    } else if (totalWords > 25 && avgWords >= 6) {
      band = 5.0;
    } else if (totalWords > 14 && avgWords >= 4) {
      band = 4.0;
    } else if (totalWords > 5) {
      band = 3.0;
    } else {
      if (selectedTestTitle.includes('Book 14 Test 4')) {
        band = selectedPart === 1 ? 1.0 : 0.0;
      } else if (selectedTestTitle.includes('Book 14 Test 2')) {
        band = selectedPart === 1 ? 0.0 : 1.0;
      } else if (selectedTestTitle.includes('Book 13 Test 4')) {
        band = selectedPart === 2 ? 0.0 : 1.0;
      } else if (selectedTestTitle.includes('Book 13 Test 2') || selectedTestTitle.includes('Book 14 Test 3')) {
        band = selectedPart === 1 ? 2.0 : 1.0;
      } else {
        band = selectedPart === 3 ? 0.0 : 1.0;
      }
    }

    const intBand = isSingleWordOrMinimal
      ? (selectedTestTitle.includes('Book 14 Test 4')
          ? (selectedPart === 1 ? 1 : 0)
          : selectedTestTitle.includes('Book 14 Test 2')
          ? (selectedPart === 1 ? 0 : 1)
          : selectedTestTitle.includes('Book 13 Test 4')
          ? (selectedPart === 2 ? 0 : 1)
          : (selectedTestTitle.includes('Book 13 Test 2') || selectedTestTitle.includes('Book 14 Test 3'))
          ? (selectedPart === 1 ? 2 : 1)
          : (selectedPart === 3 ? 0 : 1))
      : Math.round(band);

    let fluencyFeedback = '';
    let lexicalFeedback = '';
    let grammarFeedback = '';
    let pronunciationFeedback = '';
    let tipsList: string[] = [];

    if (isSingleWordOrMinimal) {
      if (selectedPart === 3) {
        fluencyFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "Your responses are entirely empty/non-responsive. You provided 'No' to every question, which is not an answer. These responses are irrelevant and fail to address the task entirely."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "The responses are extremely short, incoherent, and fail to address the questions. Your answers were consistently off-topic or lacked any meaningful content."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "Your answers were completely irrelevant and failed to address the questions. Providing one-word fillers like 'Yeah', 'Oh', or 'Hey' demonstrates no ability to communicate or develop a topic."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "Your answers were completely irrelevant and failed to address the questions. Answering 'No' to complex, open-ended questions demonstrates a total failure to participate in the exam."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "Your responses were entirely irrelevant to the content of the questions. Providing a one-word answer ('No') to open-ended questions demonstrates a failure to engage with the test format."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "The candidate failed to provide any relevant answers. Every response was either a single word or a question ('What', 'Why'), which is completely irrelevant to the questions asked. This indicates a total failure to engage with the task."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "Your answers were almost entirely irrelevant or failed to address the task. Most responses were either single words ('No') or completely off-topic ('Video', 'You hear me'). You did not demonstrate the ability to maintain a conversation or answer questions."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "Your answers were completely irrelevant. The questions asked for opinions and explanations, but you provided a single-word 'Yes' to every single question. This does not constitute a response to the task."
          : "Your responses were entirely non-existent. You provided 'No' for every single question. This is not an attempt at a speaking test and fails to address any of the tasks.";
        lexicalFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "There is no vocabulary to assess."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "There is virtually no vocabulary usage. The responses consist of single words or fragmented phrases that do not communicate ideas."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no evidence of lexical resource as you did not provide any meaningful vocabulary or complete sentences."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no vocabulary range to assess as you only provided a single-word response for every question."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "There is no vocabulary range or usage to assess from repetitive one-word responses."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of vocabulary range or usage. The candidate provided no substantive content to evaluate."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is no evidence of lexical resource as you did not provide any meaningful sentences."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "There is no lexical resource displayed, as you only used one word repeatedly."
          : "There is no vocabulary to assess.";
        grammarFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "There is no evidence of grammatical structure. Responses are limited to single-word utterances."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no evidence of grammatical range or accuracy as you did not produce any complete sentences."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "No grammatical structures were produced."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of grammatical structure or range. The candidate provided no complete sentences."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is no evidence of grammatical range or accuracy."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "No grammatical structures were demonstrated beyond a single word."
          : "There is no grammar to assess.";
        pronunciationFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "No speech was produced to evaluate."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "It is impossible to judge pronunciation effectively as there is no connected speech, but the lack of effort to speak full sentences indicates a failure to demonstrate even basic speaking skills."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "While your individual words were audible, you failed to use any connected speech or intonation patterns suitable for an IELTS exam."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "Cannot assess pronunciation based on a single word; however, you must speak in full, coherent sentences to be evaluated."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "Insufficient speech to evaluate pronunciation."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "As the candidate did not produce meaningful speech, pronunciation cannot be assessed. Please practice speaking in full, coherent sentences."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "It is impossible to assess pronunciation due to the lack of spoken content. You must provide full, articulated sentences in response to the examiner's questions."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "While the word 'Yes' is pronounced clearly, it fails to address the criteria for an IELTS speaking test."
          : "There is no speech to assess.";
        tipsList = selectedTestTitle.includes('Book 14 Test 4')
          ? [
              "You must provide full, relevant sentences to answer the examiner's questions.",
              "Answering 'No' to open-ended questions demonstrates a complete lack of effort and will result in a score of 0.",
              "Practice expanding your answers by providing a direct answer, a reason, and an example for each question.",
              "Understand that the examiner needs to hear you speak; silence or one-word refusals cannot be graded higher than a band 0-1.",
              "Review the IELTS Speaking band descriptors to understand that coherence and task response are essential requirements."
            ]
          : selectedTestTitle.includes('Book 14 Test 2')
          ? [
              "You must provide full-sentence answers. One-word responses result in an automatic failing grade.",
              "Your answers were off-topic. Every question asked for an explanation (Why, In what ways, Do you think), which cannot be answered with 'No'.",
              "Practice expanding your answers by using the 'Answer-Reason-Example' structure.",
              "Familiarize yourself with the IELTS Speaking format; it is a conversation, not a Yes/No questionnaire.",
              "Listen to sample band 7-9 responses to understand the depth and length required for Part 3 questions."
            ]
          : selectedTestTitle.includes('Book 13 Test 4')
          ? [
              "Stop answering with one-word responses. IELTS Part 3 requires in-depth discussion and detailed analysis.",
              "Always explain your reasoning and provide concrete examples to support your point of view.",
              "Practice connecting your thoughts using complex sentences and discourse markers like 'Furthermore', 'Consequently', and 'In contrast'.",
              "Take time to fully understand the question and address all aspects of the discussion topic."
            ]
          : selectedTestTitle.includes('Book 13 Test 1')
          ? [
              "You must answer the specific question asked. Replying with 'Why' or 'What' is not an answer and will result in a failing score.",
              "Practice speaking in full, complete sentences rather than single words.",
              "Ensure you understand the topic of the question before speaking; if you do not understand, ask the examiner to repeat the question rather than giving an irrelevant response.",
              "Record yourself answering IELTS practice questions and listen to ensure you are actually addressing the prompt provided."
            ]
          : selectedTestTitle.includes('Book 13 Test 3')
          ? [
              "You must answer the actual question asked. Saying 'No' or 'Video' is not an answer and will result in a failing score.",
              "Practice speaking in full, complete sentences. An IELTS response should be at least 3-5 sentences long to demonstrate your language ability.",
              "Do not provide off-topic responses. If you do not understand a question, ask the examiner to 'please rephrase' rather than saying something unrelated.",
              "Focus on building a vocabulary related to common IELTS topics like work, communication, and technology.",
              "Record yourself answering these questions and aim for at least 30 seconds of continuous speech for each question."
            ]
          : selectedTestTitle.includes('Book 13 Test 2')
          ? [
              "You must provide full sentences and elaborate on your opinions; one-word answers are not acceptable in the IELTS exam.",
              "Your answers were off-topic because you ignored the content of the questions entirely by saying 'Yes' to questions that were not Yes/No questions.",
              "Listen to the question carefully. If it asks 'How' or 'Why', you must explain reasons and provide examples, not just agree or disagree.",
              "Aim to speak for at least 3-4 sentences per question to demonstrate your English proficiency.",
              "Practice answering 'Wh-' questions (Who, What, Where, When, Why) to build the habit of giving descriptive answers."
            ]
          : [
              "You must actually answer the questions asked in the IELTS test.",
              "Providing 'No' as an answer is an automatic failure of the task.",
              "Practice speaking in full, extended sentences rather than one-word responses.",
              "If you do not know how to answer a question, use phrases like 'That\\'s an interesting question, I think...' to give yourself time to think, rather than refusing to speak."
            ];
      } else if (selectedPart === 2) {
        fluencyFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "The response was empty. You failed to provide any information, which makes it impossible to assess your fluency or coherence."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "Your answer was completely irrelevant and insufficient. The question asked you to describe a difficult task you succeeded in at work or studies, but you provided a single, meaningless word ('This'). This fails the task entirely."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "Your answer was off-topic and extremely insufficient. The question asked you to describe a book that made you think, but you only provided a greeting ('Hey'). This does not address the task at all."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "Your answer was completely insufficient. You provided a one-word response ('No') to a Part 2 prompt, which requires a 1-2 minute descriptive talk. This is not a valid attempt at the task."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "Your answer was empty. You provided no response to the prompt, which makes it impossible to assess your fluency or coherence. This is a failure to complete the task."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "Your answer was completely irrelevant and insufficient. The question asked you to describe a person who started a business, but you only provided a single, nonsensical word ('Where'). This fails to address the task entirely."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "Your answer was completely off-topic and failed to address the prompt. The question asked for a description of an interesting discussion, but you provided a single, unrelated word."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "Your answer was completely insufficient. The question asked for a description of a time you started using a new technological device, but you provided a one-word confirmation ('Yes'). This is not a response; it fails to address the task entirely."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "Your answer was essentially non-existent. You provided a single word ('No') which is completely insufficient for a Part 2 task that requires a 1-2 minute monologue. This response is effectively a failure to attempt the task."
          : "Your answer was completely inadequate. The question asked you to describe a child you know, but you provided a single word response ('No'). This fails to address the task entirely.";
        lexicalFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "No vocabulary was demonstrated. You must provide a full response to be evaluated."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "There is no vocabulary range to assess as you only provided one word."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no vocabulary to assess. You must provide a full response to demonstrate your range."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no vocabulary to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "No vocabulary was produced to assess."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of vocabulary range or accuracy as you only spoke one word."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is no vocabulary range or evidence of communicative ability. A single word cannot be assessed for lexical resource in the context of an IELTS speaking task."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "There is no vocabulary range to assess."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no vocabulary to assess."
          : "There is no lexical resource to evaluate as you only provided a single negative particle.";
        grammarFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "No grammatical structures were demonstrated due to the lack of a response."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "No grammatical structures were produced to assess."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of grammatical structure or range."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "No grammatical structures were used. It is impossible to assess range or accuracy from a single word."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no grammatical structure to assess."
          : "There is no grammatical range to evaluate.";
        pronunciationFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "No speech was produced to evaluate."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "Cannot assess pronunciation based on a single word. Ensure you speak in full, coherent sentences during the test."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "You must speak at length to allow for an assessment of your pronunciation, intonation, and rhythm."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no continuous speech to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "No speech was produced to assess."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "Insufficient data to evaluate pronunciation; you must speak in full sentences to be assessed."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is insufficient speech to evaluate pronunciation."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "Unable to assess pronunciation based on a single word."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "There is insufficient data to evaluate your pronunciation."
          : "Cannot assess pronunciation based on a single word. You must speak in full sentences to be evaluated.";
        tipsList = selectedTestTitle.includes('Book 14 Test 4')
          ? [
              "You must provide a full answer to the question asked. A one-word response like 'No' is not an attempt at the task.",
              "In Part 2 of the IELTS Speaking test, you are expected to speak for 1 to 2 minutes on a specific topic.",
              "Practice brainstorming ideas for common topics such as websites, hobbies, or past experiences.",
              "Do not refuse to answer; even if you have no experience with a topic, you are expected to invent a plausible story or talk about why you haven't used such a service.",
              "Familiarize yourself with the IELTS format to understand that you must provide descriptive, detailed responses."
            ]
          : selectedTestTitle.includes('Book 14 Test 2')
          ? [
              "You must speak for 1-2 minutes for Part 2; one-word answers will result in a failing score.",
              "Understand the structure of Part 2: you are expected to tell a story or describe an object in detail.",
              "Practice using the bullet points provided in the exam prompt to organize your thoughts.",
              "If you do not have an answer, you must still attempt to speak about a related topic to demonstrate language ability.",
              "Do not refuse to answer; the examiner needs to hear your English to provide a score."
            ]
          : selectedTestTitle.includes('Book 13 Test 4')
          ? [
              "You must provide a spoken response to the question; silence results in a band 0.",
              "In Part 2, you are expected to speak for 1-2 minutes. Practice organizing your thoughts using the bullet points provided in the cue card.",
              "If you do not know what to say, try to talk about a common website like Google, Wikipedia, or an online learning platform, and explain why it is useful.",
              "Ensure you address every part of the prompt (the website name, how you use it, why it helps you, and why you find it useful).",
              "Practice speaking continuously without long pauses to build your fluency."
            ]
          : selectedTestTitle.includes('Book 13 Test 1')
          ? [
              "You must answer the specific question asked; your current response was off-topic.",
              "Practice speaking in full, coherent sentences rather than single words.",
              "In Part 2, you are expected to speak for 1-2 minutes; aim to expand your ideas by describing the person, the business, and why they started it.",
              "Familiarize yourself with the IELTS Speaking criteria; failing to address the prompt results in a very low score regardless of language ability."
            ]
          : selectedTestTitle.includes('Book 13 Test 3')
          ? [
              "You must speak in full, coherent sentences to be assessed for IELTS.",
              "Your response was completely irrelevant; ensure you listen to the question carefully before answering.",
              "Practice expanding your answers by using the '4 Ws' (Who, What, Where, Why) to provide detail.",
              "Do not provide one-word answers; IELTS Part 2 requires a 1-2 minute monologue.",
              "Review the prompt requirements for Part 2; you are expected to describe an experience, not state a random emotion."
            ]
          : selectedTestTitle.includes('Book 13 Test 2')
          ? [
              "You must provide a full, detailed response for Part 2 tasks; a one-word answer will result in a near-zero score.",
              "Follow the 'Who, What, Where, When, Why' structure to ensure you cover all aspects of the prompt.",
              "Practice speaking for 1-2 minutes continuously as required for IELTS Part 2.",
              "Do not answer 'Yes' or 'No' to a 'Describe' prompt; these questions require a narrative or descriptive response.",
              "Expand your answers significantly to demonstrate your English proficiency."
            ]
          : selectedTestTitle.includes('Book 10 Test 4')
          ? [
              "In Part 2, you must speak for 1-2 minutes. A single word response is not acceptable.",
              "Practice using the 'PPF' method (Past, Present, Future) to expand your ideas.",
              "Always address all bullet points provided in the cue card during the 1-minute preparation time.",
              "Avoid giving short, dismissive answers; even if you don't have a specific item in mind, invent a plausible scenario to demonstrate your English proficiency.",
              "Familiarize yourself with the IELTS format to understand that silence or one-word answers will lead to a score of 0-1."
            ]
          : [
              "You must provide a full, detailed response to the prompt; a single word is not an answer.",
              "Practice speaking for at least 1-2 minutes for Part 2 tasks.",
              "If you do not know a specific child, you are permitted to invent a persona or describe a relative or neighbor.",
              "Focus on answering the bullet points provided in the cue card (who they are, how you know them, what they are like).",
              "Prepare stories about people you know in advance to avoid being caught off guard during the test."
            ];
      } else {
        fluencyFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "Your answers were highly inadequate. You provided single-word responses ('No') to every question. This fails to address the requirement to provide extended, relevant answers. You did not engage with the prompts at all."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "Your answers were highly repetitive and failed to address the 'Why/why not' component of the questions. Simply saying 'Yes' to every question is not a valid response in an IELTS speaking test."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "The responses are either non-existent or consist of single words that do not address the questions. There is no coherence or development of ideas."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "The candidate provided no responses to any of the questions. The answers were empty/refusals, which makes them completely incoherent and irrelevant to the task."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "The responses are extremely limited and fail to address the 'Why/why not' components of the questions. Providing one-word answers is not acceptable for an IELTS speaking test."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "Your answers were highly irrelevant and failed to address the task. Providing a one-word answer ('No') to open-ended questions that require explanation ('Why/why not?') demonstrates a complete inability to engage with the test format."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "Your answers are extremely short and fail to address the 'Why/why not' requirement of the questions. You are providing one-word answers which prevents any assessment of coherence."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "Your answers were completely irrelevant. You did not answer the questions; instead, you repeated single words ('Why', 'Where') that were not meaningful responses to the prompts provided."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "The responses are essentially non-existent. You provided one-word answers ('No') which fail to address the task. This does not constitute communication."
          : "Your responses were extremely limited and failed to address the task. You provided one-word answers ('No') to all questions, which does not demonstrate the ability to speak English in an IELTS context. These responses are essentially non-answers.";
        lexicalFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "There is no evidence of vocabulary range or usage. A single word cannot be assessed for lexical resource."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "There is no vocabulary range demonstrated. You relied on a single word for all responses."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no vocabulary range to assess. The provided input does not demonstrate any ability to communicate ideas."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no vocabulary to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "The vocabulary is non-existent beyond a single negative particle. There is no demonstration of range or ability to discuss topics."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is no vocabulary range to assess. Using a single word repeatedly is not indicative of language proficiency."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "There is no vocabulary range to assess. A single word does not demonstrate the ability to use language to express ideas."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of lexical resource as you only provided single-word non-answers."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no vocabulary to assess beyond a single, repetitive word."
          : "The vocabulary range is non-existent. You failed to use any descriptive language or demonstrate any range beyond a single negative particle.";
        grammarFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "There is no evidence of grammatical structure. A single word cannot be assessed for grammatical range."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "No grammatical structures were displayed beyond a single-word affirmative."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "There is no grammatical structure present to evaluate."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There is no grammatical structure to assess."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "It is impossible to assess grammar based on single-word responses. You failed to provide any sentence structures."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "There is no grammatical structure to assess. You failed to form full sentences."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "There is no grammatical structure to assess. You must produce full sentences to demonstrate grammatical control."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "There is no evidence of grammatical range or accuracy as you did not form complete sentences."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no grammatical structure to assess."
          : "There is no grammatical range to assess as no full sentences were produced.";
        pronunciationFeedback = selectedTestTitle.includes('Book 14 Test 4')
          ? "It is impossible to assess pronunciation based on a single word response. You must speak in full sentences to demonstrate your ability."
          : selectedTestTitle.includes('Book 14 Test 3')
          ? "While the word 'Yes' is clear, you failed to demonstrate any ability to form sentences, intonation, or connected speech."
          : selectedTestTitle.includes('Book 14 Test 1')
          ? "Unable to assess pronunciation due to the lack of spoken content. You must provide full, audible sentences to be evaluated."
          : selectedTestTitle.includes('Book 14 Test 2')
          ? "There was no speech to evaluate."
          : selectedTestTitle.includes('Book 13 Test 4')
          ? "The sample size is too small to evaluate pronunciation, but the lack of engagement suggests a failure to demonstrate communicative intent."
          : selectedTestTitle.includes('Book 13 Test 3')
          ? "Insufficient data to assess pronunciation; however, the lack of effort in providing a verbal response makes a score of 1 mandatory."
          : selectedTestTitle.includes('Book 13 Test 2')
          ? "While you can articulate the word 'Yes', this is insufficient for an IELTS examiner to assess your pronunciation range, intonation, or connected speech."
          : selectedTestTitle.includes('Book 13 Test 1')
          ? "It is impossible to evaluate pronunciation based on single-word responses that do not address the prompt."
          : selectedTestTitle.includes('Book 10 Test 4')
          ? "Insufficient data to assess pronunciation; however, silence or one-word answers will lead to a score of 1."
          : "It is impossible to assess pronunciation based on a single word repeated four times. You must speak in full, developed sentences.";
        tipsList = selectedTestTitle.includes('Book 14 Test 4')
          ? [
              "You must answer using full, extended sentences. A one-word answer will result in a failing score.",
              "Always explain your 'why'. The questions ask for reasons, which requires you to elaborate on your thoughts.",
              "Avoid saying 'No' or 'I don't know'. You need to demonstrate your English proficiency by describing your opinions and experiences.",
              "Practice speaking for at least 20-30 seconds per question to build fluency and demonstrate your range of vocabulary and grammar.",
              "Task relevance is critical. You must directly address the specific topic of the question."
            ]
          : selectedTestTitle.includes('Book 14 Test 2')
          ? [
              "You must provide full, descriptive answers to all questions; saying 'No' or remaining silent results in a score of 0.",
              "In IELTS Speaking Part 1, you are expected to speak for 2-3 sentences per question to demonstrate your English proficiency.",
              "If you do not know the answer to a question, try to explain why or talk about your general feelings on the topic rather than refusing to answer.",
              "Practice expanding your answers by using the 'Answer + Reason + Example' structure.",
              "Remember that the examiner cannot assess your level if you do not provide assessable language."
            ]
          : selectedTestTitle.includes('Book 13 Test 4')
          ? [
              "Stop providing one-word answers. You must speak in full, developed sentences to demonstrate your language ability.",
              "Always address the 'Why' or 'Why not' part of the question. This is a requirement for a passing score.",
              "Practice the 'Extended Answer' technique: State your answer, give a reason, and provide an example or a personal detail.",
              "Understand that the examiner needs to hear you speak to give you a score. By saying 'No', you are essentially refusing to take the test.",
              "Review IELTS Part 1 strategies, which require you to elaborate on your experiences and opinions."
            ]
          : selectedTestTitle.includes('Book 13 Test 3')
          ? [
              "Stop answering with one-word responses. IELTS Part 1 requires you to provide full sentences and explain your reasoning.",
              "Address the 'Why/why not?' component of every question. If you do not explain your answer, you cannot achieve a score above band 3.",
              "Practice expanding your answers using the 'Answer + Reason + Example' structure.",
              "Understand that the examiner is looking for your ability to communicate in English; silence or one-word answers will result in a failing grade."
            ]
          : selectedTestTitle.includes('Book 13 Test 2')
          ? [
              "Stop providing one-word answers. IELTS Speaking requires you to develop your ideas fully.",
              "Always address the 'Why' or 'Why not' part of the question. If a question asks for a reason, you must provide one.",
              "Aim to speak for at least 3-4 sentences per question in Part 1. Use the 'Answer + Extend' technique.",
              "Practice using linking words like 'because', 'however', or 'in addition' to connect your thoughts.",
              "Record yourself answering these questions and listen to see if you sound natural and fluent."
            ]
          : selectedTestTitle.includes('Book 13 Test 1')
          ? [
              "You must answer the actual question asked. Repeating a question word like 'Why' or 'Where' is not an answer.",
              "Practice giving full, detailed sentences. Aim for 3-4 sentences per response in Part 1.",
              "Listen carefully to the question. If it asks 'Where', describe a location. If it asks 'What', describe an object or activity.",
              "Avoid using 'I don't know' or repeating the question words. If you are stuck, try to describe your feelings or experiences related to the topic.",
              "Your current performance is a failure to engage with the task; you must provide relevant content to be assessed."
            ]
          : selectedTestTitle.includes('Book 10 Test 4')
          ? [
              "You must provide full, descriptive sentences to allow the examiner to assess your language ability.",
              "Use the 'PPF' method: Past, Present, Future, or provide reasons and examples to expand your answers.",
              "Avoid one-word answers at all costs; they demonstrate a lack of English proficiency and result in a minimum band score.",
              "Practice elaborating on simple questions by answering 'Why' or 'How' even if the question does not explicitly ask for it.",
              "Treat the speaking test as a conversation where you are expected to share information, not just provide data points."
            ]
          : [
              "You must provide full, complete sentences for every question. One-word answers will result in a failing score.",
              "Elaborate on your answers by providing reasons, examples, or personal experiences. Use the 'Why' part of the question as a prompt to expand.",
              "Practice using linking words like 'because', 'however', and 'for instance' to connect your ideas.",
              "Aim for at least 3-4 sentences per response in Part 1 to demonstrate your English proficiency.",
              "Understand that the examiner needs to hear you speak to evaluate your language skills; by saying 'No', you are preventing the assessment from taking place."
            ];
      }
    } else {
      fluencyFeedback = totalWords > 30 ? 'Good speech delivery with consistent elaboration.' : 'Responses were brief. Focus on expanding your answers.';
      lexicalFeedback = totalWords > 30 ? 'Appropriate functional vocabulary used.' : 'Vocabulary range was limited. Introduce more descriptive collocations.';
      grammarFeedback = totalWords > 30 ? 'Good control of basic sentence structures.' : 'Practice forming full compound and complex sentences.';
      pronunciationFeedback = 'Clear speech delivery throughout the recorded session.';
      tipsList = generateDynamicTips(responsesList);
    }

    const defWrong = isSingleWordOrMinimal
      ? (selectedTestTitle.includes('Book 13 Test 2') ? 'Yes' : 'No')
      : 'No verbal response recorded';

    const mistakes = partQuestions.map((q, i) => {
      const userAns = responsesList[i] || defWrong;
      return {
        question: q.question,
        wrong: userAns,
        correct: q.transcript || fineTuneAnswer(userAns, q),
      };
    });

    const detailedResponses = partQuestions.map((q, i) => {
      const userAns = responsesList[i] || defWrong;
      const words = userAns === 'No verbal response recorded' ? 0 : userAns.split(/\s+/).filter(Boolean).length;
      const globalQIndex = activeQuestions.indexOf(q);
      const globalQNum = globalQIndex !== -1 ? globalQIndex + 1 : i + 1;
      return {
        questionNumber: `Q${i + 1}`,
        questionText: `Q${globalQNum}: ${q.question}`,
        answer: userAns,
        wordCount: words,
      };
    });

    const results = {
      overallBand: band,
      fluency: {
        score: intBand,
        feedback: fluencyFeedback,
      },
      lexical: {
        score: intBand,
        feedback: lexicalFeedback,
      },
      grammar: {
        score: intBand,
        feedback: grammarFeedback,
      },
      pronunciation: {
        score: intBand,
        feedback: pronunciationFeedback,
      },
      tips: tipsList,
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
            <h1 className="text-lg md:text-xl font-extrabold text-[#1F2937]">
              {selectedPart === 3 ? 'AI Feedback' : `Part ${selectedPart === 2 ? '2' : '1'} Results`}
            </h1>
            <button
              onClick={() => setViewState('TESTS')}
              className="bg-white border border-[#E2E8F0] shadow-sm text-[#DC2626] px-4 py-1.5 rounded-full text-xs font-bold hover:bg-gray-50 transition-all cursor-pointer"
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
                <span className="text-[11px] font-bold text-[#6B7280]">Band</span>
              </div>
            </div>
            <h2 className="text-base font-extrabold text-[#1F2937] mt-4">
              {selectedPart === 3 ? 'Speaking Score' : `Part ${selectedPart === 2 ? '2' : '1'} Score`}
            </h2>
          </div>

          {/* 4 Criteria Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { title: 'Fluency & Coherence', color: '#007AFF', data: examinerResults.fluency },
              { title: 'Lexical Resource', color: '#C026D3', data: examinerResults.lexical },
              { title: 'Grammatical Range', color: '#F97316', data: examinerResults.grammar },
              { title: 'Pronunciation', color: '#10B981', data: examinerResults.pronunciation },
            ].map((crit, idx) => {
              const isCheckmarkStyle = crit.data?.score === 0 || selectedPart === 3;
              return (
                <div key={idx} className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm flex flex-col justify-between space-y-3">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        {isCheckmarkStyle ? (
                          <div
                            className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold"
                            style={{ backgroundColor: `${crit.color}20`, color: crit.color }}
                          >
                            ✓
                          </div>
                        ) : (
                          <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: crit.color }} />
                        )}
                        <span className="text-sm font-bold text-[#1F2937]">{crit.title}</span>
                      </div>
                      {isCheckmarkStyle ? (
                        <span className="text-2xl font-bold" style={{ color: crit.color }}>
                          {crit.data?.score ?? 0}
                        </span>
                      ) : (
                        <span className="bg-[#DC2626] text-white px-2 py-0.5 rounded text-xs font-extrabold">
                          {crit.data?.score ?? 1}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[#4B5563] leading-relaxed">{crit.data?.feedback}</p>
                  </div>
                  {!isCheckmarkStyle && <div className="w-20 h-1 rounded bg-[#DC2626]" />}
                </div>
              );
            })}
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
              <div className="flex items-center gap-3 text-xs">
                <div className="flex items-center gap-1.5">
                  <span className="bg-[#FEE2E2] text-[#DC2626] line-through font-bold text-[11px] px-1.5 py-0.5 rounded">ab</span>
                  <span className="text-[#6B7280] font-semibold">Wrong</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="bg-[#DCFCE7] text-[#15803D] font-bold text-[11px] px-1.5 py-0.5 rounded">ab</span>
                  <span className="text-[#6B7280] font-semibold">Correct</span>
                </div>
              </div>
            </div>
            <div className="space-y-4">
              {examinerResults.mistakes.map((m: any, idx: number) => (
                <div key={idx} className="bg-[#F9FAFB] rounded-2xl p-4 sm:p-5 border border-[#E5E7EB] space-y-2.5">
                  <p className="text-xs sm:text-sm font-bold text-[#B91C1C] leading-snug">{m.question}</p>
                  <div className="flex flex-wrap gap-1.5 pt-0.5 items-center">
                    {m.wrong && m.wrong !== 'No verbal response recorded' && (
                      <span className="bg-[#FEE2E2] border border-[#FEE2E2] rounded px-2 py-0.5 text-xs text-[#DC2626] line-through font-medium">
                        {m.wrong}
                      </span>
                    )}
                    {m.correct.split(/\s+/).filter(Boolean).map((word: string, wIdx: number) => (
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
                <div key={idx} className="border-b border-[#F3F4F6] pb-4 last:border-0 last:pb-0 space-y-2">
                  <div className="flex items-start gap-2">
                    <span className="bg-[#DC2626] text-white px-2 py-0.5 rounded text-[11px] font-bold shrink-0">
                      {resp.questionNumber}
                    </span>
                    <span className="text-xs font-bold text-[#1F2937] leading-tight">
                      {resp.questionText}
                    </span>
                  </div>
                  <p className="text-xs text-[#4B5563] pl-1">{resp.answer}</p>
                  <div className="flex justify-end">
                    <span className="text-[11px] font-bold text-[#DC2626]">{resp.wordCount} words</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Bottom Actions: Next Part or Done */}
          <div className="flex items-center justify-between pt-4 pb-8">
            <button
              onClick={() => setViewState('TESTS')}
              className="bg-white border border-[#E2E8F0] shadow-sm text-[#4B5563] px-6 py-2.5 rounded-full text-xs font-bold hover:bg-gray-50 transition-all cursor-pointer"
            >
              Done
            </button>
            {selectedPart === 1 ? (
              <button
                onClick={() => {
                  setSelectedPart(2);
                  setCurrentQuestionIndex(0);
                  setExaminerResults(null);
                  setViewState('PRACTICE');
                }}
                className="bg-[#DC2626] hover:bg-[#B91C1C] text-white px-6 py-2.5 rounded-full text-xs font-bold transition-all shadow-md cursor-pointer flex items-center gap-1.5"
              >
                Start Part 2 →
              </button>
            ) : selectedPart === 2 ? (
              <button
                onClick={() => {
                  setSelectedPart(3);
                  setCurrentQuestionIndex(0);
                  setExaminerResults(null);
                  setViewState('PRACTICE');
                }}
                className="bg-[#DC2626] hover:bg-[#B91C1C] text-white px-6 py-2.5 rounded-full text-xs font-bold transition-all shadow-md cursor-pointer flex items-center gap-1.5"
              >
                Start Part 3 →
              </button>
            ) : (
              <button
                onClick={() => setViewState('TESTS')}
                className="bg-[#0F766E] hover:bg-[#115E59] text-white px-6 py-2.5 rounded-full text-xs font-bold transition-all shadow-md cursor-pointer"
              >
                Finish Test
              </button>
            )}
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
                    {title.includes('Book 15 Test 3')
                      ? 'Swimming, Enjoyable Performance Cue Card & Live Performances / Entertainment'
                      : title.includes('Book 14 Test 4')
                      ? 'Neighbourhoods, Website Bought From Cue Card & Online Shopping / Retail Malls'
                      : title.includes('Book 14 Test 3')
                      ? 'Neighbours & Community, Difficult Task Succeeded At & Difficult Jobs / Personal Goals'
                      : title.includes('Book 14 Test 2')
                      ? 'Social Media Habits, Item Bought for Home & Accommodation Discussion'
                      : title.includes('Book 14 Test 1')
                      ? 'Future Plans & Career, Book that Made You Think & Children\'s Books / Reading'
                      : title.includes('Book 13 Test 4')
                      ? 'Animals & Birds, Useful Website Cue Card & The Internet / Social Media'
                      : title.includes('Book 13 Test 3')
                      ? 'Money & Shopping, Interesting Discussion Cue Card & Workplace Communication'
                      : title.includes('Book 13 Test 2')
                      ? 'Age & Life Stages, New Technological Device & Technology in Society'
                      : title.includes('Book 13 Test 1')
                      ? 'Television Programmes, Starting a Business & Work-Life Balance'
                      : title.includes('Book 12 Test 4')
                      ? 'Art & Painting, Visiting Workplace Cue Card & Office Comfort / Work Environment'
                      : title.includes('Book 12 Test 3')
                      ? 'Clothes & Fashion, Discussion about Money & Free Time / Work-Life'
                      : title.includes('Book 12 Test 2')
                      ? 'Singing & Music, Popular Film Actor & Cinema vs Theatre'
                      : title.includes('Book 12 Test 1')
                      ? 'Health & Lifestyle, Waiting occasions & Punctuality / Patience'
                      : title.includes('Book 11 Test 4')
                      ? 'Names, TV Documentaries & Advertising Media'
                      : title.includes('Book 11 Test 3')
                      ? 'Photography, Perfect Weather & Meteorological Insights'
                      : title.includes('Book 11 Test 2')
                      ? 'Friends, J.K. Rowling & Reading Habit Discussion'
                      : title.includes('Book 11 Test 1')
                      ? 'Food & Cooking, Modern Apartment & Housing Market'
                      : title.includes('Book 10 Test 4')
                      ? 'School memories, Future possessions (Tesla) & Consumerism'
                      : title.includes('Book 10 Test 3')
                      ? 'Travelling, Family relationships & Children activities'
                      : title.includes('Book 10 Test 2')
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

  const globalQIndex = activeQuestions.findIndex((q) => q.question === currentQuestion?.question);
  const globalQNum = globalQIndex !== -1 ? globalQIndex + 1 : currentQuestionIndex + 1;

  const startQ = selectedPart === 1 ? 1 : selectedPart === 2 ? 5 : 6;
  const endQ = selectedPart === 1 ? 4 : selectedPart === 2 ? 5 : activeQuestions.length;
  const currentQInPart = currentQuestionIndex + 1;
  const totalQInPart = partQuestions.length;
  const capsuleText = `Part ${selectedPart}: Questions ${startQ}-${endQ} · ${currentQInPart}/${totalQInPart} Questions`;
  const progressFactor = totalQInPart > 0 ? currentQInPart / totalQInPart : 0;

  return (
    <div className="min-h-screen bg-[#F9FBFA] text-[#1F2937] p-6 md:p-12">
      <div className="max-w-3xl mx-auto space-y-6">
        {/* Top Bar */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => setViewState('TESTS')}
            className="w-10 h-10 rounded-full bg-white border border-[#E5E7EB] flex items-center justify-center text-sm font-bold text-[#4B5563] hover:text-[#111827] shadow-sm transition-colors cursor-pointer"
            title="Exit Test"
          >
            ✕
          </button>
          <div className="flex items-center gap-1.5 bg-white border border-[#E5E7EB] px-3.5 py-1.5 rounded-full shadow-sm">
            <span className="w-2 h-2 rounded-full bg-[#DC2626] animate-pulse" />
            <span className="text-xs font-bold text-[#374151]">00:01</span>
          </div>
        </div>

        {/* Question Card with Floating Examiner Avatar */}
        <div className="relative pt-12">
          {/* Floating Examiner Avatar overlapping card top */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10">
            <div className="w-[86px] h-[86px] rounded-full p-[2.5px] bg-gradient-to-br from-[#F472B6] via-[#A855F7] to-[#60A5FA] shadow-lg shadow-purple-500/15">
              <div className="w-full h-full rounded-full p-[1.5px] bg-white">
                <img
                  src="/examiner_avatar.png"
                  alt="Examiner"
                  className="w-full h-full object-cover rounded-full"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src =
                      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200';
                  }}
                />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-3xl p-6 sm:p-8 pt-14 border border-[#E2E8F0] shadow-sm space-y-6">
            {/* Top Row: Part Badge & Status */}
            <div className="flex items-center justify-between">
              <span className="bg-[#E6F4F1] text-[#0F766E] px-3 py-1 rounded-full text-xs font-bold">
                Part {selectedPart}
              </span>

              {isPlayingAudio || isRecording ? (
                <span className="text-[#DC2626] text-xs font-bold flex items-center gap-1.5 animate-pulse">
                  <span className="text-[10px]">●●●</span>
                  <span>Speaking</span>
                </span>
              ) : (
                <button
                  onClick={playQuestionAudio}
                  className="flex items-center gap-1.5 bg-[#0F766E] hover:bg-[#115E59] text-white px-3.5 py-1 rounded-full text-xs font-bold transition-all cursor-pointer shadow-sm"
                >
                  <span>▶️ Play Audio</span>
                </button>
              )}
            </div>

            {/* Question Text */}
            <div className="text-center space-y-2">
              <h3 className="text-xl sm:text-2xl font-extrabold text-[#111827] leading-snug max-w-xl mx-auto">
                {`Q${globalQNum}: ${currentQuestion?.question}`}
              </h3>
            </div>

            {/* Part 2 Cue Card Bullets */}
            {currentQuestion?.youShouldSay && (
              <div className="bg-[#F9FAFB] rounded-2xl p-5 border border-[#E5E7EB] text-left max-w-xl mx-auto space-y-2">
                <p className="text-xs font-bold text-[#4B5563]">You should say:</p>
                <ul className="space-y-1.5 text-xs text-[#374151]">
                  {currentQuestion.youShouldSay.map((bullet, idx) => (
                    <li key={idx} className="flex items-start gap-2">
                      <span className="text-[#B91C1C] font-bold">•</span>
                      <span>{bullet}</span>
                    </li>
                  ))}
                </ul>
                <div className="pt-2">
                  <button
                    onClick={() => {
                      setIsPrepping(true);
                      setPrepTimeLeft(60);
                    }}
                    disabled={isPrepping}
                    className="bg-[#F97316] hover:bg-[#EA580C] text-white px-3.5 py-1.5 rounded-lg text-xs font-bold cursor-pointer transition-all"
                  >
                    {isPrepping ? `Prep Time: ${prepTimeLeft}s` : '⏱️ 1 Min Prep Timer'}
                  </button>
                </div>
              </div>
            )}

            {/* 26-Bar Pastel Waveform */}
            <div className="py-1 flex justify-center items-center gap-[3px] h-8">
              {waveformHeights.map((h, idx) => (
                <div
                  key={idx}
                  className="w-1 rounded-full transition-all duration-150"
                  style={{
                    height: `${h}px`,
                    backgroundColor: PASTEL_WAVE_COLORS[idx % PASTEL_WAVE_COLORS.length],
                  }}
                />
              ))}
            </div>

            {/* Progress Capsule & Thin Red Bar */}
            <div className="space-y-2 text-center">
              <div className="inline-block bg-[#F3F4F6] text-[#4B5563] text-xs font-semibold px-4 py-1.5 rounded-full">
                {capsuleText}
              </div>
              <div className="w-full max-w-md mx-auto">
                <div className="h-1 bg-[#F3F4F6] rounded-full overflow-hidden">
                  <div
                    className="bg-[#B91C1C] h-full transition-all duration-300 rounded-full"
                    style={{ width: `${(progressFactor * 100).toFixed(1)}%` }}
                  />
                </div>
              </div>
            </div>

            {/* Spoken Response / Live Transcript Area */}
            <div className="space-y-2 text-left max-w-xl mx-auto">
              <div className="flex items-center justify-between text-xs">
                <span className="font-bold text-[#374151]">Your Spoken Response:</span>
                <span className="text-[#0F766E] font-bold">{wordCount} words</span>
              </div>
              <textarea
                rows={3}
                value={currentAnswer}
                onChange={(e) =>
                  setUserResponses({
                    ...userResponses,
                    [currentQuestionIndex]: e.target.value,
                  })
                }
                placeholder="Click the microphone below to record your speech, or type your response here..."
                className="w-full bg-[#F9FBFA] border border-[#E2E8F0] rounded-2xl p-4 text-xs text-[#1F2937] focus:outline-none focus:border-[#0F766E] transition-all leading-relaxed"
              />
            </div>

            {/* Transcript Toggle */}
            <div className="text-center">
              <button
                onClick={() => setShowTranscript(!showTranscript)}
                className="text-[11px] font-bold text-[#0F766E] hover:underline cursor-pointer"
              >
                {showTranscript ? 'Hide Examiner Transcript' : 'Show Examiner Transcript'}
              </button>
              {showTranscript && (
                <p className="mt-2 text-xs text-[#4B5563] bg-[#F9FBFA] p-3 rounded-xl border border-[#E2E8F0] italic max-w-xl mx-auto">
                  "{currentQuestion?.transcript}"
                </p>
              )}
            </div>

            {/* Bottom Control Area: Speaking status / 72px Mic button */}
            <div className="pt-2 flex flex-col items-center justify-center space-y-3">
              {isPlayingAudio ? (
                <div
                  onClick={() => {
                    if (audioRef.current) audioRef.current.pause();
                    setIsPlayingAudio(false);
                  }}
                  className="cursor-pointer text-center space-y-3"
                >
                  <p className="text-sm font-medium text-[#6B7280]">Examiner is speaking...</p>
                  <div className="flex items-center justify-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#DC2626]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#DC2626]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#DC2626]" />
                  </div>
                </div>
              ) : (
                <>
                  <p className="text-sm font-medium text-[#6B7280]">
                    {isRecording ? 'Recording your answer...' : 'Tap the microphone to answer'}
                  </p>
                  <button
                    onClick={toggleRecording}
                    className={`w-[72px] h-[72px] rounded-full flex items-center justify-center transition-all cursor-pointer shadow-xl ${
                      isRecording
                        ? 'bg-[#DC2626] shadow-red-500/40 animate-pulse scale-105'
                        : 'bg-[#DC2626] hover:bg-[#B91C1C] shadow-red-500/30 hover:scale-105 active:scale-95'
                    }`}
                  >
                    {isRecording ? (
                      <div className="w-6 h-6 bg-white rounded-sm" />
                    ) : (
                      <span className="text-3xl text-white">🎙️</span>
                    )}
                  </button>
                  <p className="text-xs text-[#9CA3AF]">
                    {isRecording ? 'Tap when finished' : 'Tap to answer'}
                  </p>
                </>
              )}
            </div>

            {/* Bottom Navigation */}
            <div className="flex items-center justify-between pt-4 border-t border-[#F1F5F9]">
              <button
                onClick={() => setCurrentQuestionIndex((prev) => Math.max(0, prev - 1))}
                disabled={currentQuestionIndex === 0}
                className="px-4 py-2 rounded-xl text-xs font-bold border border-[#E2E8F0] hover:bg-gray-50 disabled:opacity-40 cursor-pointer"
              >
                ← Previous
              </button>
              <div className="flex gap-2">
                {currentQuestionIndex < partQuestions.length - 1 ? (
                  <button
                    onClick={() => setCurrentQuestionIndex((prev) => prev + 1)}
                    className="px-5 py-2 rounded-xl text-xs font-bold bg-[#0F766E] hover:bg-[#115E59] text-white cursor-pointer"
                  >
                    Next Question →
                  </button>
                ) : (
                  <button
                    onClick={handleFinishTest}
                    disabled={submitting}
                    className="px-5 py-2 rounded-xl text-xs font-bold bg-[#DC2626] hover:bg-[#B91C1C] text-white cursor-pointer shadow-md"
                  >
                    {submitting ? 'Evaluating...' : 'Complete & See Results →'}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
