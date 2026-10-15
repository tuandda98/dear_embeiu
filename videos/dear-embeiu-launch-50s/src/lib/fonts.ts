import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";
// The app's one family (lib/theme/app_theme.dart): Quicksand, bundled static TTFs 300–700; weight 800 maps to the
// Bold file exactly as the app declares it. Full Vietnamese coverage (checked with fontTools: ỗ ợ ả ữ ẫ đ).
const W = [
  ["Light", "300"],
  ["Regular", "400"],
  ["Medium", "500"],
  ["SemiBold", "600"],
  ["Bold", "700"],
  ["Bold", "800"],
] as const;
export const fontReady = Promise.all(
  W.map(([file, weight]) => loadFont({ family: "Quicksand", url: staticFile(`fonts/Quicksand-${file}.ttf`), weight, format: "truetype" })),
);
