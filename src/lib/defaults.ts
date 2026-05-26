// Runlini 스토어 스크린샷 편집기의 초기 프로젝트 상태를 제공한다.
import { DEFAULT_LOCALE } from "./locale";
import type { Device, ProjectState, Slide } from "./types";

let _id = 0;
export const nid = () => `s_${Date.now().toString(36)}_${(_id++).toString(36)}`;

const en = (s: string) => ({ [DEFAULT_LOCALE]: s });

const shot = (root: string, n: number) =>
  `${root}/{locale}/${String(n).padStart(2, "0")}.png`;

function makeRunliniSlides(root: string): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("기록 레이스"),
      headline: en("내 기록과\n다시 달리기"),
      screenshot: shot(root, 3),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("실시간 비교"),
      headline: en("앞섬과 뒤처짐을\n바로 확인"),
      screenshot: shot(root, 4),
      inverted: true,
    },
    {
      id: nid(),
      layout: "two-devices",
      label: en("기록 홈"),
      headline: en("목표와 기록을\n한눈에"),
      screenshot: shot(root, 1),
      screenshotSecondary: shot(root, 3),
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("오늘 추천"),
      headline: en("출발 전\n기록 선택"),
      screenshot: shot(root, 2),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("러닝 준비"),
      headline: en("위치와 음성 안내를\n내 방식대로"),
      screenshot: shot(root, 5),
      inverted: true,
    },
  ];
}

function tabletStarter(root: string): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("기록 레이스"),
      headline: en("내 기록과\n다시 달리기"),
      screenshot: shot(root, 3),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("실시간 비교"),
      headline: en("앞섬과 뒤처짐을\n바로 확인"),
      screenshot: shot(root, 4),
      inverted: true,
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("러닝 준비"),
      headline: en("위치와 음성 안내를\n내 방식대로"),
      screenshot: shot(root, 5),
    },
  ];
}

function fgStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "feature-graphic",
      label: {},
      headline: en("내 기록과 다시 달리는 러닝 앱"),
      screenshot: "/screenshots/android/phone/{locale}/03.png",
    },
  ];
}

export const DEFAULT_PROJECT: ProjectState = {
  appName: "런린이",
  themeId: "runlini-clean",
  locales: [DEFAULT_LOCALE],
  locale: DEFAULT_LOCALE,
  device: "android",
  orientation: "portrait",
  appIcon: "/app-icon.png",
  slidesByDevice: {
    iphone: makeRunliniSlides("/screenshots/apple/iphone"),
    android: makeRunliniSlides("/screenshots/android/phone"),
    ipad: tabletStarter("/screenshots/apple/ipad"),
    "android-7": tabletStarter("/screenshots/android/tablet-7/portrait"),
    "android-10": tabletStarter("/screenshots/android/tablet-10/portrait"),
    "feature-graphic": fgStarter(),
  },
};

export function newSlide(layout: Slide["layout"] = "device-bottom"): Slide {
  return {
    id: nid(),
    layout,
    label: en("NEW"),
    headline: en("Edit this\nheadline."),
    screenshot: "",
  };
}

export function detectPlatform(device: Device): "ios" | "android" {
  return device === "iphone" || device === "ipad" ? "ios" : "android";
}
