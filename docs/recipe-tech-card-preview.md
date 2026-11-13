# Recipe technology cards — preview setup

This feature is isolated on branch feature/recipe-tech-card-ai-20261113.

## What it does

- Admin / production roles can open «Технологические карты» from the admin dashboard.
- The screen accepts up to eight recipe photos.
- The recipe-tech-card Edge Function validates the signed-in Supabase user and role, reads the ingredient catalogue, sends the photos to the Gemini API with JSON output, and returns structured recipe data.
- Ingredient names not found in the catalogue are inserted with needs_review = true.
- Missing prices are collected in the app before the TTK is saved.
- Price conversion is limited to compatible dimensions: kg/g, l/ml, and pcs.
- The app stores the recipe, gross quantity, optional net quantity/loss, technology, storage guidance, quality description, yield, cost and nutrition fields.

## Required server secret

Create a Gemini API key in Google AI Studio (https://aistudio.google.com/) and set GEMINI_API_KEY as an Edge Function secret in the development Supabase branch only. Never put it in Flutter source, app configuration, GitHub, or a client-side environment file.

Optional: GEMINI_MODEL — defaults to gemini-3.8-flash. The Gemini API currently lists a free tier for this model, subject to rate limits and Google AI Studio terms. Free-tier prompts/responses may be used by Google to improve its products; do not upload confidential recipes or customer data without reviewing those terms.

The function performs its own auth.getUser(token) check because platform JWT verification is disabled for compatibility with asymmetric Supabase signing keys. Requests without a valid user session or an allowed production role are rejected.

## Database and deployment

1. Apply supabase/migrations/20261113090000_recipe_tech_cards.sql to the development database.
2. Add the GEMINI_API_KEY secret to that development project.
3. Deploy supabase/functions/recipe-tech-card/index.ts as recipe-tech-card.
4. Run database security advisors and verify the Data API grants/RLS.
5. Build the Flutter app and test with sample recipes before merging anything to production.

Do not apply this migration or deploy the function to vslast-production until the preview has been accepted.

## Calculation boundaries

- Recipe amounts in grams/kilograms and millilitres/litres are converted only within the same dimension.
- Pieces are not converted to grams without a known piece weight.
- Cups, spoons, pinches and other volume/weight measures without ingredient-specific density are not guessed; the recipe needs manual correction.
- Missing purchase prices leave the total cost incomplete.
- Nutrition is calculated only when ingredient nutrition data, compatible gram quantities and a known finished yield are available. Generic starter nutrition values are marked as estimates and should be checked against supplier labels.
- This is a draft TTK assistant; the technologist must confirm ambiguous handwriting, yields, losses, storage conditions and nutrition before operational use.