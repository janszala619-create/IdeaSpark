const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildPrompt,
  createIdeaWithOpenAI,
  extractResponseText,
  normalizeIdeaPayload,
  normalizePrompt,
  validateFilter,
  webSearchTool,
} = require("./generate-idea");

test("validateFilter accepts missing filters and known raw values", () => {
  assert.equal(validateFilter(undefined, ["webApp"], "category"), undefined);
  assert.equal(validateFilter("webApp", ["webApp"], "category"), "webApp");
});

test("validateFilter rejects unknown raw values", () => {
  assert.throws(
    () => validateFilter("website", ["webApp"], "category"),
    /Invalid category/,
  );
});

test("buildPrompt keeps requested category and difficulty", () => {
  const prompt = buildPrompt({
    category: "mobileApp",
    difficulty: "beginner",
    prompt: "Fitness fuer Studenten mit Gamification",
  });

  assert.match(prompt, /Kategorie: mobileApp/);
  assert.match(prompt, /Schwierigkeit: beginner/);
  assert.match(prompt, /Fitness fuer Studenten mit Gamification/);
  assert.match(prompt, /vollstaendige App-Idee/);
  assert.match(prompt, /Recherchiere zuerst aktuelle/);
  assert.match(prompt, /Inspiration-Seed fuer Varianz/);
  assert.match(prompt, /isAIGenerated immer auf true/);
});

test("normalizePrompt trims whitespace and limits length", () => {
  assert.equal(normalizePrompt("  Fitness   Kalender  "), "Fitness Kalender");
  assert.equal(normalizePrompt("   "), undefined);
  assert.equal(normalizePrompt("x".repeat(700)).length, 600);
});

test("normalizePrompt rejects non-string values", () => {
  assert.throws(() => normalizePrompt(["bad"]), /Invalid prompt/);
});

test("webSearchTool enables web search with a German default location", () => {
  const tool = webSearchTool();

  assert.equal(tool.type, "web_search");
  assert.equal(tool.search_context_size, "medium");
  assert.equal(tool.user_location.country, "DE");
});

test("extractResponseText reads the Responses API convenience field", () => {
  assert.equal(extractResponseText({ output_text: "{\"title\":\"Idea\"}" }), "{\"title\":\"Idea\"}");
});

test("extractResponseText reads nested message content", () => {
  const response = {
    output: [
      {
        type: "message",
        content: [
          {
            type: "output_text",
            text: "{\"title\":\"Idea\"}",
          },
        ],
      },
    ],
  };

  assert.equal(extractResponseText(response), "{\"title\":\"Idea\"}");
});

test("normalizeIdeaPayload forces requested filters and AI marker", () => {
  const idea = normalizeIdeaPayload(
    {
      id: "550e8400-e29b-41d4-a716-446655440000",
      title: "StudySprint",
      summary: "Eine fokussierte Lern-App fuer kurze taegliche Uebungen.",
      category: "webApp",
      difficulty: "advanced",
      features: ["Timer", "Tagesziele", "Fortschritt"],
      extensionIdea: "Spaetere Synchronisation ueber mehrere Geraete.",
      isAIGenerated: false,
    },
    {
      category: "mobileApp",
      difficulty: "beginner",
    },
  );

  assert.equal(idea.category, "mobileApp");
  assert.equal(idea.difficulty, "beginner");
  assert.equal(idea.isAIGenerated, true);
});

test("createIdeaWithOpenAI sends a structured Responses API request", async () => {
  const previousKey = process.env.OPENAI_API_KEY;
  const previousModel = process.env.OPENAI_MODEL;
  process.env.OPENAI_API_KEY = "test-key";
  process.env.OPENAI_MODEL = "test-model";

  let capturedRequest;
  const idea = await createIdeaWithOpenAI({
    category: "tool",
    difficulty: "intermediate",
    prompt: "GitHub Release Checklisten fuer Solo-Entwickler",
    fetchImpl: async (url, options) => {
      capturedRequest = { url, options };
      return {
        ok: true,
        async json() {
          return {
            output_text: JSON.stringify({
              id: "550e8400-e29b-41d4-a716-446655440000",
              title: "BuildBuddy",
              summary: "Ein kleines Werkzeug, das Checklisten fuer App-Releases generiert.",
              category: "tool",
              difficulty: "intermediate",
              features: ["Release-Checkliste", "Export", "Statusanzeige"],
              extensionIdea: "Team-Freigaben und GitHub-Integration ergaenzen.",
              isAIGenerated: true,
            }),
          };
        },
      };
    },
  });

  if (previousKey === undefined) {
    delete process.env.OPENAI_API_KEY;
  } else {
    process.env.OPENAI_API_KEY = previousKey;
  }

  if (previousModel === undefined) {
    delete process.env.OPENAI_MODEL;
  } else {
    process.env.OPENAI_MODEL = previousModel;
  }

  assert.equal(capturedRequest.url, "https://api.openai.com/v1/responses");
  assert.equal(capturedRequest.options.method, "POST");
  assert.equal(capturedRequest.options.headers.Authorization, "Bearer test-key");

  const body = JSON.parse(capturedRequest.options.body);
  assert.equal(body.model, "test-model");
  assert.deepEqual(body.tools.map((tool) => tool.type), ["web_search"]);
  assert.equal(body.tool_choice, "required");
  assert.equal(body.reasoning.effort, "low");
  assert.match(body.input[1].content, /GitHub Release Checklisten fuer Solo-Entwickler/);
  assert.equal(body.text.format.type, "json_schema");
  assert.equal(body.text.format.strict, true);
  assert.equal(idea.category, "tool");
  assert.equal(idea.difficulty, "intermediate");
});
