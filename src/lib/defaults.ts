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
      label: en("RECORD RACE"),
      headline: en("Race your\nown record."),
      screenshot: shot(root, 4),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("LIVE CLARITY"),
      headline: en("Know if\nyou're ahead."),
      screenshot: shot(root, 5),
      inverted: true,
    },
    {
      id: nid(),
      layout: "two-devices",
      label: en("RUN LOG"),
      headline: en("Every route\nstays useful."),
      screenshot: shot(root, 1),
      screenshotSecondary: shot(root, 4),
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("ONE TAP START"),
      headline: en("Open the map.\nStart fast."),
      screenshot: shot(root, 2),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("RUN READY"),
      headline: en("Cues, goals\nand backup."),
      screenshot: shot(root, 3),
      inverted: true,
    },
  ];
}

function tabletStarter(root: string): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("RECORD RACE"),
      headline: en("Race your\nown record."),
      screenshot: shot(root, 4),
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("LIVE CLARITY"),
      headline: en("Know if\nyou're ahead."),
      screenshot: shot(root, 5),
      inverted: true,
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("RUN READY"),
      headline: en("Cues, goals\nand backup."),
      screenshot: shot(root, 3),
    },
  ];
}

function fgStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "feature-graphic",
      label: {},
      headline: en("Race your record.\nSee the gap live."),
      screenshot: "/screenshots/android/phone/{locale}/05.png",
    },
  ];
}

export const DEFAULT_PROJECT: ProjectState = {
  appName: "Runlini",
  themeId: "runlini-dark",
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
