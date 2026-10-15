import { Config } from "@remotion/cli/config";

Config.setEntryPoint("src/index.ts");
Config.setChromiumOpenGlRenderer("angle");
Config.setVideoImageFormat("png"); // lossless frames for the ProRes master
