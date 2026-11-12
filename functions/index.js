const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// Set these with:
//   firebase functions:secrets:set OPENAI_API_KEY
//   firebase functions:secrets:set SPOTIFY_CLIENT_ID
//   firebase functions:secrets:set SPOTIFY_CLIENT_SECRET
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const SPOTIFY_CLIENT_ID = defineSecret("SPOTIFY_CLIENT_ID");
const SPOTIFY_CLIENT_SECRET = defineSecret("SPOTIFY_CLIENT_SECRET");

const SPOTIFY_SECRETS = [SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  return request.auth.uid;
}

async function askChatGPT(systemPrompt, userMessage) {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini", // fast and cheap model
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
    }),
  });

  if (!response.ok) {
    logger.error("OpenAI request failed", response.status, await response.text());
    throw new HttpsError("internal", "AI request failed.");
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content ?? "";
}

// Cached per function instance, so warm instances reuse the token.
let spotifyToken = null;
let spotifyTokenExpiresAt = 0;

async function getSpotifyToken() {
  if (spotifyToken && Date.now() < spotifyTokenExpiresAt) {
    return spotifyToken;
  }

  const credentials = Buffer.from(
    `${SPOTIFY_CLIENT_ID.value()}:${SPOTIFY_CLIENT_SECRET.value()}`
  ).toString("base64");

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ grant_type: "client_credentials" }),
  });

  if (!response.ok) {
    logger.error("Spotify token request failed", response.status, await response.text());
    throw new HttpsError("internal", "Could not authenticate with Spotify.");
  }

  const body = await response.json();
  spotifyToken = body.access_token;
  // Refresh a minute early to avoid using a token right as it expires.
  spotifyTokenExpiresAt = Date.now() + (body.expires_in - 60) * 1000;
  return spotifyToken;
}

async function spotifyGet(path, params) {
  const url = new URL(`https://api.spotify.com/v1${path}`);
  if (params) url.search = new URLSearchParams(params).toString();

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${await getSpotifyToken()}` },
  });

  if (!response.ok) {
    logger.error("Spotify request failed", path, response.status, await response.text());
    throw new HttpsError("internal", "Spotify request failed.");
  }
  return response.json();
}

async function searchSpotifyTracks(query, limit) {
  const data = await spotifyGet("/search", {
    q: query,
    type: "track",
    limit: String(limit),
  });
  return data.tracks?.items ?? [];
}

// ---------------------------------------------------------------------------
// Callable functions
// ---------------------------------------------------------------------------

// Search Spotify tracks for the journal song picker.
exports.searchTracks = onCall({ secrets: SPOTIFY_SECRETS }, async (request) => {
  requireAuth(request);

  const query = String(request.data?.query ?? "").trim();
  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 20);
  if (!query) return [];

  return searchSpotifyTracks(query, limit);
});

// Look up a single track's cover art, name and artist.
exports.getTrack = onCall({ secrets: SPOTIFY_SECRETS }, async (request) => {
  requireAuth(request);

  const id = String(request.data?.id ?? "");
  if (!/^[A-Za-z0-9]+$/.test(id)) {
    throw new HttpsError("invalid-argument", "Invalid track id.");
  }

  const track = await spotifyGet(`/tracks/${id}`);
  const images = track.album?.images ?? [];
  return {
    imageUrl: images.length > 0 ? images[0].url : "",
    name: track.name,
    artist: track.artists?.[0]?.name ?? "",
  };
});

// Ask ChatGPT for 3 songs in the user's preferred genre, then find each on Spotify.
exports.getRecommendedSongs = onCall(
  { secrets: [OPENAI_API_KEY, ...SPOTIFY_SECRETS] },
  async (request) => {
    const uid = requireAuth(request);

    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    const prefSongGenre = userDoc.get("preferredGenre");
    if (!prefSongGenre) return [];

    const aiResponse = await askChatGPT(
      "Given the user's preferred music genre, find 3 songs with varying emotion from that genre. Only state the name of the songs, with a forwards slash to separate each song name.",
      `My preferred music genre is ${prefSongGenre}.`
    );

    const songNames = aiResponse
      .split("/")
      .map((name) => name.trim())
      .filter((name) => name.length > 0);

    const results = await Promise.all(
      songNames.map((name) =>
        searchSpotifyTracks(name, 1).catch((e) => {
          logger.warn(`Search failed for "${name}"`, e);
          return [];
        })
      )
    );

    // One top track per recommended song, skipping songs with no match.
    return results.filter((items) => items.length > 0).map((items) => items[0]);
  }
);

// Analyze a journal entry + chosen song: returns a written overview and a 1-100 intensity score.
exports.getJournalInsights = onCall({ secrets: [OPENAI_API_KEY] }, async (request) => {
  requireAuth(request);

  const journal = String(request.data?.journal ?? "");
  const songName = String(request.data?.songName ?? "");
  const emotion = String(request.data?.emotion ?? "");
  if (!journal.trim()) {
    throw new HttpsError("invalid-argument", "Journal text is required.");
  }

  const userMessage = `${journal}. The name of the song I chose was ${songName}. The main emotion I felt was ${emotion}`;

  const [overview, intensityText] = await Promise.all([
    askChatGPT(
      "You are to shortly analyze this person's journal of the day they had, and you are to analyze what feelings and emotions this person went through. You will then analyze the lyrics of the song provided and give an analysis on how those lyrics connect to the day that the person had. If the song has no lyrics, base your analysis off of other characterizing criteria, like tempo or genre. Analyze only what is said in the text, do not assume or make up any new information about the user. It is ok to be less analytical if the user didn’t provide much information. Finally, provide targeted, highly specific advice based exclusively on the events described. Address the author directly using second-person pronouns ('you'). Keep it concise and specific by choosing words with specific meaning that reflects the author's day. Keep your summary under a paragraph. Maintain a clinical, objective, and strictly analytical tone. Do not act like a supportive therapist. Completely avoid supportive filler phrases like 'I encourage you to,' 'Remember that,' or 'It is essential to.' Keep your response under 4 sentences total. Be dense with meaning and avoid wordy transitions.",
      userMessage
    ),
    askChatGPT(
      "You are to analyze this person's journal of the day they had and the song they chose to go with it. Then, give a score from 1 to 100 about how intense the emotion they picked was that day. YOU MAY ONLY RESPOND WITH A SINGLE NUMBER, NOTHING ELSE.",
      userMessage
    ),
  ]);

  const parsed = parseInt(intensityText.match(/\d+/)?.[0] ?? "", 10);
  const intensity = Number.isNaN(parsed) ? null : Math.min(Math.max(parsed, 1), 100);

  return { overview, intensity };
});

// Permanently delete the signed-in user's account: journals, profile, profile picture, and login.
exports.deleteAccount = onCall(async (request) => {
  const uid = requireAuth(request);

  // Only allow this right after the user re-entered their password (within 5 minutes).
  const authTime = request.auth.token.auth_time * 1000;
  if (Date.now() - authTime > 5 * 60 * 1000) {
    throw new HttpsError("failed-precondition", "Please re-enter your password and try again.");
  }

  // Deletes users/{uid} and every subcollection (journal_entries).
  await admin.firestore().recursiveDelete(admin.firestore().collection("users").doc(uid));

  await admin
    .storage()
    .bucket()
    .file(`user_profiles/${uid}.jpg`)
    .delete({ ignoreNotFound: true });

  await admin.auth().deleteUser(uid);
  logger.info(`Deleted account ${uid}`);
  return { deleted: true };
});
