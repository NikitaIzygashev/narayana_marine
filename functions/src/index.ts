import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";

const placesApiKey = defineSecret("GOOGLE_PLACES_API_KEY");
const placeId = defineSecret("GOOGLE_PLACES_PLACE_ID");

const placesFieldMask = [
  "displayName",
  "rating",
  "userRatingCount",
  "reviews",
  "googleMapsUri",
  "formattedAddress",
].join(",");

type PlacesText = {text?: string};
type PlacesReview = {
  authorAttribution?: {displayName?: string; photoUri?: string};
  rating?: number;
  text?: PlacesText;
  originalText?: PlacesText;
  relativePublishTimeDescription?: string;
};
type PlacesDetails = {
  displayName?: PlacesText;
  rating?: number;
  userRatingCount?: number;
  reviews?: PlacesReview[];
  googleMapsUri?: string;
  formattedAddress?: string;
};

type PublicReviewsResponse = {
  rating: number | null;
  reviewCount: number | null;
  googleMapsUri: string | null;
  formattedAddress: string | null;
  reviews: Array<{
    authorName: string;
    photoUrl: string | null;
    rating: number | null;
    text: string;
    originalText: string | null;
    relativeDate: string | null;
  }>;
};

const cache = new Map<string, {expiresAt: number; value: PublicReviewsResponse}>();
const cacheTtlMs = 10 * 60 * 1000;

function supportedLanguage(value: unknown): "en" | "ru" {
  return value === "ru" ? "ru" : "en";
}

/**
 * Publicly callable because the website is public. It has no arbitrary place
 * input and reads both the key and approved place ID from Secret Manager.
 */
export const getGoogleReviews = onCall(
  {region: "asia-southeast1", secrets: [placesApiKey, placeId]},
  async (request) => {
    const languageCode = supportedLanguage(request.data?.languageCode);
    const configuredPlaceId = placeId.value();
    const apiKey = placesApiKey.value();

    if (!configuredPlaceId || !apiKey) {
      logger.warn("Google Places review integration is not configured.");
      throw new HttpsError("failed-precondition", "Reviews are not configured.");
    }

    const cached = cache.get(languageCode);
    if (cached != null && cached.expiresAt > Date.now()) {
      return cached.value;
    }

    let response: Response;
    try {
      response = await fetch(
        `https://places.googleapis.com/v1/places/${encodeURIComponent(configuredPlaceId)}?languageCode=${languageCode}`,
        {
          headers: {
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask": placesFieldMask,
          },
        },
      );
    } catch (error) {
      logger.error("Places API request failed.", error);
      throw new HttpsError("unavailable", "Reviews are temporarily unavailable.");
    }

    if (!response.ok) {
      logger.error("Places API returned an error.", {status: response.status});
      throw new HttpsError("unavailable", "Reviews are temporarily unavailable.");
    }

    const place = (await response.json()) as PlacesDetails;
    const result: PublicReviewsResponse = {
      rating: place.rating ?? null,
      reviewCount: place.userRatingCount ?? null,
      googleMapsUri: place.googleMapsUri ?? null,
      formattedAddress: place.formattedAddress ?? null,
      reviews: (place.reviews ?? []).map((review) => ({
        authorName: review.authorAttribution?.displayName ?? "",
        photoUrl: review.authorAttribution?.photoUri ?? null,
        rating: review.rating ?? null,
        // Places supplies localized text for the requested language when it
        // exists. Keep the original text available for future UI support.
        text: review.text?.text ?? "",
        originalText: review.originalText?.text ?? null,
        relativeDate: review.relativePublishTimeDescription ?? null,
      })),
    };
    cache.set(languageCode, {expiresAt: Date.now() + cacheTtlMs, value: result});
    return result;
  },
);
