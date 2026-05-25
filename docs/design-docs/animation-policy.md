# Animation Policy

Runlini motion exists to make state changes readable while running. It must not compete with large map controls, pace numbers, or primary decisions.

## Principles

- Keep splash and brand startup static.
- Avoid decorative background motion, Lottie, long route transitions, and staggered list choreography.
- Prefer local transitions inside the affected control or card over full-screen movement.
- Respect `MediaQuery.disableAnimations`. Reduced motion must render the final readable state without fade, scale, slide, shimmer, or size animation.
- Keep loading feedback subtle on true black and graphite surfaces.

## Timing

- Fast transition: 80ms.
- Short transition: 140ms.
- Standard transition: 220ms.
- Countdown step: 1000ms.
- Skeleton shimmer: 900ms.

## Curves

- Entering content uses `easeOutCubic`.
- Exiting content uses `easeInCubic`.
- Size changes use the same enter curve unless the widget needs separate enter and exit curves.

## Screen Rules

- Countdown scrim stays static. The number may fade and scale only when animations are enabled.
- Start, pause, resume, and stop controls must update text and color first. Motion is secondary and must stay short.
- Running dashboard expand and collapse may animate size, but reduced motion must swap the layout without animation.
- Record race picker cards may animate expanded content and route preview loading inside the card. Loading must never block list scrolling.
- History calendar week and month changes may use size and fade. Narrow viewports must not overflow during the transition.
- Detail and settings screens use skeleton-to-content or value crossfade only where data state changes.
