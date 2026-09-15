import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BandUp IELTS",
  description: "Master the IELTS Exam with personalized AI speaking, writing, reading, and listening practice.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased" suppressHydrationWarning>
      <body className="min-h-full flex flex-col font-sans">{children}</body>
    </html>
  );
}
