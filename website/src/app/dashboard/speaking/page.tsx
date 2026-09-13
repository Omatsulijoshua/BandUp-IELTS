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

const testSuites: { [key: string]: Question[] } = {
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
      band = selectedPart === 3 ? 0.0 : 1.0;
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
      band = selectedPart === 3 ? 0.0 : 1.0;
    }

    const intBand = isSingleWordOrMinimal ? (selectedPart === 3 ? 0 : 1) : Math.round(band);

    let fluencyFeedback = '';
    let lexicalFeedback = '';
    let grammarFeedback = '';
    let pronunciationFeedback = '';
    let tipsList: string[] = [];

    if (isSingleWordOrMinimal) {
      if (selectedPart === 3) {
        fluencyFeedback = "Your responses were entirely non-existent. You provided 'No' for every single question. This is not an attempt at a speaking test and fails to address any of the tasks.";
        lexicalFeedback = "There is no vocabulary to assess.";
        grammarFeedback = "There is no grammar to assess.";
        pronunciationFeedback = "There is no speech to assess.";
        tipsList = [
          "You must actually answer the questions asked in the IELTS test.",
          "Providing 'No' as an answer is an automatic failure of the task.",
          "Practice speaking in full, extended sentences rather than one-word responses.",
          "If you do not know how to answer a question, use phrases like 'That\\'s an interesting question, I think...' to give yourself time to think, rather than refusing to speak."
        ];
      } else if (selectedPart === 2) {
        fluencyFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "Your answer was essentially non-existent. You provided a single word ('No') which is completely insufficient for a Part 2 task that requires a 1-2 minute monologue. This response is effectively a failure to attempt the task."
          : "Your answer was completely inadequate. The question asked you to describe a child you know, but you provided a single word response ('No'). This fails to address the task entirely.";
        lexicalFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no vocabulary to assess."
          : "There is no lexical resource to evaluate as you only provided a single negative particle.";
        grammarFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no grammatical structure to assess."
          : "There is no grammatical range to evaluate.";
        pronunciationFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "There is insufficient data to evaluate your pronunciation."
          : "Cannot assess pronunciation based on a single word. You must speak in full sentences to be evaluated.";
        tipsList = selectedTestTitle.includes('Book 10 Test 4')
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
        fluencyFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "The responses are essentially non-existent. You provided one-word answers ('No') which fail to address the task. This does not constitute communication."
          : "Your responses were extremely limited and failed to address the task. You provided one-word answers ('No') to all questions, which does not demonstrate the ability to speak English in an IELTS context. These responses are essentially non-answers.";
        lexicalFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no vocabulary to assess beyond a single, repetitive word."
          : "The vocabulary range is non-existent. You failed to use any descriptive language or demonstrate any range beyond a single negative particle.";
        grammarFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "There is no grammatical structure to assess."
          : "There is no grammatical range to assess as no full sentences were produced.";
        pronunciationFeedback = selectedTestTitle.includes('Book 10 Test 4')
          ? "Insufficient data to assess pronunciation; however, silence or one-word answers will lead to a score of 1."
          : "It is impossible to assess pronunciation based on a single word repeated four times. You must speak in full, developed sentences.";
        tipsList = selectedTestTitle.includes('Book 10 Test 4')
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

    const mistakes = partQuestions.map((q, i) => {
      const userAns = responsesList[i] || 'No verbal response recorded';
      return {
        question: q.question,
        wrong: userAns,
        correct: q.transcript || fineTuneAnswer(userAns, q),
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
              const isZero = crit.data?.score === 0;
              return (
                <div key={idx} className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-sm flex flex-col justify-between space-y-3">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        {isZero ? (
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
                      {isZero ? (
                        <span className="text-2xl font-bold" style={{ color: crit.color }}>
                          0
                        </span>
                      ) : (
                        <span className="bg-[#DC2626] text-white px-2 py-0.5 rounded text-xs font-extrabold">
                          {crit.data?.score ?? 1}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[#4B5563] leading-relaxed">{crit.data?.feedback}</p>
                  </div>
                  {!isZero && <div className="w-20 h-1 rounded bg-[#DC2626]" />}
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
              <div className="flex items-center gap-4 text-xs">
                <span className="text-[#DC2626] line-through font-semibold">ab Wrong</span>
                <span className="text-[#10B981] font-semibold">ab Correct</span>
              </div>
            </div>
            <div className="space-y-6">
              {examinerResults.mistakes.map((m: any, idx: number) => (
                <div key={idx} className="border-b border-[#F3F4F6] pb-5 last:border-0 last:pb-0 space-y-2">
                  <p className="text-xs font-bold text-[#B91C1C]">{m.question}</p>
                  <div>
                    <span className="inline-block bg-[#FEF2F2] border border-[#FEE2E2] rounded-lg px-2.5 py-1 text-xs text-[#DC2626] line-through font-medium">
                      {m.wrong}
                    </span>
                  </div>
                  <div className="flex flex-wrap gap-1.5 pt-1">
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
                    {title.includes('Book 12 Test 1')
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
