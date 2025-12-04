import { PollyConfig, VoiceEngine, MoodStyle } from "../types";
import { buildSSML, buildStrongerSSML, buildCrystalSSML } from "./ssmlService";

// Helper function to get feature engine (same as in processUserInput.ts)
function getFeatureEngine(
  pollyConfig: PollyConfig,
  strongerMode: boolean,
  crystalVoice: boolean
): VoiceEngine {
  const featureEngines = pollyConfig.featureEngines;

  if (strongerMode) {
    return featureEngines?.stronger || pollyConfig.engine;
  } else if (crystalVoice) {
    return featureEngines?.crystal || pollyConfig.engine;
  } else {
    return featureEngines?.main || pollyConfig.engine;
  }
}

describe("Feature-wise Voice Engine Selection", () => {
  const baseConfig: PollyConfig = {
    region: "us-east-1",
    engine: "generative",
    outputFormat: "mp3",
    timeoutSeconds: 10,
  };

  describe("getFeatureEngine", () => {
    it("should return main engine for normal mode", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "neural",
          stronger: "generative",
          crystal: "standard",
        },
      };

      const engine = getFeatureEngine(config, false, false);
      expect(engine).toBe("neural");
    });

    it("should return stronger engine for stronger mode", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "neural",
          stronger: "generative",
          crystal: "standard",
        },
      };

      const engine = getFeatureEngine(config, true, false);
      expect(engine).toBe("generative");
    });

    it("should return crystal engine for crystal voice mode", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "neural",
          stronger: "generative",
          crystal: "standard",
        },
      };

      const engine = getFeatureEngine(config, false, true);
      expect(engine).toBe("standard");
    });

    it("should fallback to default engine when featureEngines is undefined", () => {
      const config: PollyConfig = {
        ...baseConfig,
        engine: "neural",
      };

      expect(getFeatureEngine(config, false, false)).toBe("neural");
      expect(getFeatureEngine(config, true, false)).toBe("neural");
      expect(getFeatureEngine(config, false, true)).toBe("neural");
    });

    it("should handle all engines being the same", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "standard",
          stronger: "standard",
          crystal: "standard",
        },
      };

      expect(getFeatureEngine(config, false, false)).toBe("standard");
      expect(getFeatureEngine(config, true, false)).toBe("standard");
      expect(getFeatureEngine(config, false, true)).toBe("standard");
    });

    it("should handle different engines for each feature", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "generative",
          stronger: "neural",
          crystal: "standard",
        },
      };

      expect(getFeatureEngine(config, false, false)).toBe("generative");
      expect(getFeatureEngine(config, true, false)).toBe("neural");
      expect(getFeatureEngine(config, false, true)).toBe("standard");
    });
  });

  describe("SSML generation with different engines", () => {
    const testText = "Hello, this is a test message.";

    describe("buildSSML", () => {
      it("should generate generative engine SSML", () => {
        const ssml = buildSSML(testText, "generative", MoodStyle.microDare, {
          microDare: { rate: "medium", pitch: "medium", volume: "medium" },
        });
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("</speak>");
        expect(ssml).toContain("rate=");
        expect(ssml).toContain("volume=");
      });

      it("should generate neural engine SSML", () => {
        const ssml = buildSSML(testText, "neural", MoodStyle.microDare, {
          microDare: { rate: "medium", pitch: "medium", volume: "medium" },
        });
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("</speak>");
        expect(ssml).toContain("volume=");
      });

      it("should generate standard engine SSML", () => {
        const ssml = buildSSML(testText, "standard", MoodStyle.microDare, {
          microDare: { rate: "medium", pitch: "medium", volume: "medium" },
        });
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("</speak>");
        expect(ssml).toContain("rate=");
        expect(ssml).toContain("pitch=");
        expect(ssml).toContain("volume=");
      });
    });

    describe("buildStrongerSSML", () => {
      it("should generate generative engine SSML for stronger mode", () => {
        const ssml = buildStrongerSSML(testText, "generative");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("x-loud");
      });

      it("should generate neural engine SSML for stronger mode", () => {
        const ssml = buildStrongerSSML(testText, "neural");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("+6dB");
      });

      it("should generate standard engine SSML for stronger mode", () => {
        const ssml = buildStrongerSSML(testText, "standard");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("<emphasis");
      });
    });

    describe("buildCrystalSSML", () => {
      it("should generate generative engine SSML for crystal voice", () => {
        const ssml = buildCrystalSSML(testText, "generative");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("x-slow");
        expect(ssml).toContain("x-soft");
      });

      it("should generate neural engine SSML for crystal voice", () => {
        const ssml = buildCrystalSSML(testText, "neural");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("amazon:effect");
        expect(ssml).toContain("drc");
      });

      it("should generate standard engine SSML for crystal voice", () => {
        const ssml = buildCrystalSSML(testText, "standard");
        expect(ssml).toContain("<speak>");
        expect(ssml).toContain("amazon:effect");
        expect(ssml).toContain("phonation");
      });
    });
  });

  describe("Engine priority fallback", () => {
    it("should prioritize stronger mode over crystal voice when both are true", () => {
      const config: PollyConfig = {
        ...baseConfig,
        featureEngines: {
          main: "standard",
          stronger: "generative",
          crystal: "neural",
        },
      };

      // When both are true, stronger mode takes priority
      const engine = getFeatureEngine(config, true, true);
      expect(engine).toBe("generative");
    });
  });
});
