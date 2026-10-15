// Act 5 · Nói trước (1920–2280). Reads the GLOBAL frame. 1920–1949 is pure C.ink (the hard cut lands on silence).
import { useCurrentFrame } from "remotion";
import { A5Scene } from "./a5/Scene.tsx";

export const Act5: React.FC = () => <A5Scene f={useCurrentFrame()} />;
