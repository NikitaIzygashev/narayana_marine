/**
 * Deliberately not deployed as a public endpoint. Run this only from a trusted
 * owner environment with GOOGLE_PLACES_API_KEY set, inspect the candidates,
 * and then save the verified ID through Firebase Secret Manager.
 */
const query = "Narayana Marine Phuket Thailand";
const fieldMask = "places.id,places.displayName,places.formattedAddress,places.googleMapsUri";

async function main(): Promise<void> {
  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    throw new Error("GOOGLE_PLACES_API_KEY must be set in the trusted shell.");
  }

  const response = await fetch("https://places.googleapis.com/v1/places:searchText", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask": fieldMask,
    },
    body: JSON.stringify({textQuery: query, languageCode: "en"}),
  });

  if (!response.ok) {
    throw new Error(`Places Text Search failed: ${response.status}`);
  }
  console.log(JSON.stringify(await response.json(), null, 2));
}

void main();
