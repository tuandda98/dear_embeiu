import { useEffect, useState } from "react";
import { cancelRender, continueRender, delayRender } from "remotion";
import { fontReady } from "./fonts.ts";

/** hold the frame until Inter + Geist Mono have loaded (scenes measure text with them) */
export function useFonts() {
  const [hold] = useState(() => delayRender("fonts before measuring text"));
  const [ready, setReady] = useState(false);
  useEffect(() => void fontReady.then(() => setReady(true), cancelRender), []);
  useEffect(() => {
    if (ready) continueRender(hold);
  }, [ready, hold]);
  return ready;
}
