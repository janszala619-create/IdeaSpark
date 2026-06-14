const CATEGORY_VALUES = [
  "webApp",
  "mobileApp",
  "artificialIntelligence",
  "game",
  "tool",
  "automation",
];

const DIFFICULTY_VALUES = ["beginner", "intermediate", "advanced"];

const ideaSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "id",
    "title",
    "summary",
    "category",
    "difficulty",
    "features",
    "extensionIdea",
    "isAIGenerated",
  ],
  properties: {
    id: {
      type: "string",
      description: "A UUID string.",
    },
    title: {
      type: "string",
      minLength: 3,
      maxLength: 60,
    },
    summary: {
      type: "string",
      minLength: 20,
      maxLength: 260,
    },
    category: {
      type: "string",
      enum: CATEGORY_VALUES,
    },
    difficulty: {
      type: "string",
      enum: DIFFICULTY_VALUES,
    },
    features: {
      type: "array",
      minItems: 3,
      maxItems: 5,
      items: {
        type: "string",
        minLength: 3,
        maxLength: 80,
      },
    },
    extensionIdea: {
      type: "string",
      minLength: 10,
      maxLength: 160,
    },
    isAIGenerated: {
      type: "boolean",
    },
  },
};

function sendJson(res, statusCode, payload) {
  res.statusCode = statusCode;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.end(JSON.stringify(payload));
}

function readJsonBody(req) {
  if (req.body && typeof req.body === "object") {
    return Promise.resolve(req.body);
  }

  if (typeof req.body === "string") {
    return Promise.resolve(JSON.parse(req.body));
  }

  return new Promise((resolve, reject) => {
    let body = "";

    req.on("data", (chunk) => {
      body += chunk;
    });

    req.on("end", () => {
      if (!body.trim()) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(body));
      } catch (error) {
        reject(error);
      }
    });

    req.on("error", reject);
  });
}

function validateFilter(value, allowedValues, fieldName) {
  if (value === undefined || value === null || value === "") {
    return undefined;
  }

  if (typeof value !== "string" || !allowedValues.includes(value)) {
    throw new Error(`Invalid ${fieldName}`);
  }

  return value;
}

function normalizePrompt(prompt) {
  if (prompt === undefined || prompt === null) {
    return undefined;
  }

  if (typeof prompt !== "string") {
    throw new Error("Invalid prompt");
  }

  const normalizedPrompt = prompt.replace(/\s+/g, " ").trim();
  if (!normalizedPrompt) {
    return undefined;
  }

  return normalizedPrompt.slice(0, 600);
}

function buildPrompt({ category, difficulty, prompt }) {
  const categoryLine = category
    ? `Kategorie: ${category}`
    : `Kategorie: waehle genau eine aus ${CATEGORY_VALUES.join(", ")}`;
  const difficultyLine = difficulty
    ? `Schwierigkeit: ${difficulty}`
    : `Schwierigkeit: waehle genau eine aus ${DIFFICULTY_VALUES.join(", ")}`;
  const promptLine = prompt
    ? `Nutzer-Stichworte und Wunschkontext: ${prompt}`
    : "Nutzer-Stichworte: keine angegeben; finde selbst einen aktuellen, konkreten Bedarf.";
  const inspirationSeed = `${Date.now()}-${crypto.randomUUID()}`;

  return [
    "Recherchiere zuerst aktuelle Produkt-, Developer-, Startup-, App- und Automatisierungstrends im Web.",
    "Erstelle danach genau eine frische Software-Projektidee fuer die native iOS-App IdeaSpark.",
    promptLine,
    "Mache aus den Stichworten eine vollstaendige App-Idee mit Zielgruppe, klarem Nutzen, konkreten Kernfeatures und einer realistischen Erweiterung.",
    categoryLine,
    difficultyLine,
    `Inspiration-Seed fuer Varianz: ${inspirationSeed}`,
    "Antworte auf Deutsch, aber verwende fuer category und difficulty exakt die erlaubten Raw Values.",
    "Vermeide generische Standardideen wie einfache Todo-Listen, Wetter-Apps, Budget-Tracker oder Habit-Tracker, ausser du kombinierst sie mit einem ungewoehnlichen aktuellen Kontext.",
    "Nenne keine Quellen im JSON und kopiere keine Produktnamen; nutze Web-Funde nur als Inspiration.",
    "Die Idee soll praktisch umsetzbar sein und keine API-Schluessel, Geheimnisse oder illegalen Inhalte benoetigen.",
    "Gib kurze, konkrete Feature-Namen und eine sinnvolle Erweiterungsidee zurueck.",
    "Setze isAIGenerated immer auf true.",
  ].join("\n");
}

function webSearchTool() {
  return {
    type: "web_search",
    search_context_size: process.env.OPENAI_WEB_SEARCH_CONTEXT || "medium",
    user_location: {
      type: "approximate",
      country: process.env.OPENAI_SEARCH_COUNTRY || "DE",
    },
  };
}

function extractResponseText(responseJson) {
  if (typeof responseJson.output_text === "string") {
    return responseJson.output_text;
  }

  for (const item of responseJson.output || []) {
    for (const content of item.content || []) {
      if (typeof content.text === "string") {
        return content.text;
      }
    }
  }

  throw new Error("OpenAI response did not contain text output");
}

function normalizeIdeaPayload(payload, requestedFilters = {}) {
  const idea = {
    id: typeof payload.id === "string" ? payload.id : crypto.randomUUID(),
    title: String(payload.title || "").trim(),
    summary: String(payload.summary || "").trim(),
    category: requestedFilters.category || payload.category,
    difficulty: requestedFilters.difficulty || payload.difficulty,
    features: Array.isArray(payload.features)
      ? payload.features.map((feature) => String(feature).trim()).filter(Boolean)
      : [],
    extensionIdea: String(payload.extensionIdea || "").trim(),
    isAIGenerated: true,
  };

  if (!CATEGORY_VALUES.includes(idea.category)) {
    throw new Error("Generated idea contains invalid category");
  }

  if (!DIFFICULTY_VALUES.includes(idea.difficulty)) {
    throw new Error("Generated idea contains invalid difficulty");
  }

  if (!idea.title || !idea.summary || idea.features.length < 3 || !idea.extensionIdea) {
    throw new Error("Generated idea is incomplete");
  }

  return idea;
}

async function createIdeaWithOpenAI({ category, difficulty, prompt, fetchImpl = fetch }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    const error = new Error("OPENAI_API_KEY is not configured");
    error.statusCode = 500;
    throw error;
  }

  const response = await fetchImpl("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || "gpt-5.5",
      reasoning: {
        effort: process.env.OPENAI_REASONING_EFFORT || "low",
      },
      tools: [webSearchTool()],
      tool_choice: "required",
      input: [
        {
          role: "system",
          content:
            "Du bist ein kreativer Produktcoach. Du recherchierst aktuelle Signale im Web und gibst danach ausschliesslich valides JSON entsprechend dem Schema zurueck.",
        },
        {
          role: "user",
          content: buildPrompt({ category, difficulty, prompt }),
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "ideaspark_project_idea",
          strict: true,
          schema: ideaSchema,
        },
      },
    }),
  });

  const responseJson = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message = responseJson.error?.message || "OpenAI request failed";
    const error = new Error(message);
    error.statusCode = response.status >= 500 ? 502 : response.status;
    throw error;
  }

  const outputText = extractResponseText(responseJson);
  return normalizeIdeaPayload(JSON.parse(outputText), { category, difficulty });
}

async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    sendJson(res, 405, { error: "Method not allowed" });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch {
    sendJson(res, 400, { error: "Invalid JSON body" });
    return;
  }

  let category;
  let difficulty;
  let prompt;
  try {
    category = validateFilter(body.category, CATEGORY_VALUES, "category");
    difficulty = validateFilter(body.difficulty, DIFFICULTY_VALUES, "difficulty");
    prompt = normalizePrompt(body.prompt);
  } catch (error) {
    sendJson(res, 400, { error: error.message });
    return;
  }

  try {
    const idea = await createIdeaWithOpenAI({ category, difficulty, prompt });
    sendJson(res, 200, idea);
  } catch (error) {
    console.error(error);
    sendJson(res, error.statusCode || 502, {
      error: "AI idea generation failed",
    });
  }
}

module.exports = handler;
module.exports.CATEGORY_VALUES = CATEGORY_VALUES;
module.exports.DIFFICULTY_VALUES = DIFFICULTY_VALUES;
module.exports.buildPrompt = buildPrompt;
module.exports.createIdeaWithOpenAI = createIdeaWithOpenAI;
module.exports.extractResponseText = extractResponseText;
module.exports.normalizeIdeaPayload = normalizeIdeaPayload;
module.exports.normalizePrompt = normalizePrompt;
module.exports.validateFilter = validateFilter;
module.exports.webSearchTool = webSearchTool;
