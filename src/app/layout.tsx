// 스토어 스크린샷 편집기 화면과 동작을 구성한다.
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "런린이 Google Play Screenshots",
  description: "Design and export Runlini Google Play screenshots.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
