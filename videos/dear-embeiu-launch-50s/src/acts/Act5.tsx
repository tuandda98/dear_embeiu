// Act 5 · Nói trước (1920–2280). Reads the GLOBAL frame. 1920–1949 is pure C.ink (the hard cut lands on silence).
import { useCurrentFrame } from "remotion";
import { Blur } from "../components/Blur.tsx";
import { A5Dots, A5Scene, dotsFast } from "./a5/Scene.tsx";

/** the dots read the (sub-)frame themselves, so <Blur> can sample their glide */
const Dots: React.FC = () => <A5Dots f={useCurrentFrame()} />;

export const Act5: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <>
      <A5Scene f={f} />
      <Blur on={dotsFast(f)}>
        <Dots />
      </Blur>
    </>
  );
};
