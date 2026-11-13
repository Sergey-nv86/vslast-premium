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

## Isolated mobile preview project

The preview Supabase project is already provisioned separately from production:

- Project: `vslast-recipe-tech-preview`
- Project ref: `lpuzgzgyxqfwnwpfbefw`
- Region: `eu-central-1`
- Project URL: `https://lpuzgzgyxqfwnwpfbefw.supabase.co`
- Organization: `snocwyuqqemdvxwkywxf`
- Project creation estimate: USD 0/month

The preview app has a dedicated email/password entry screen enabled only with `RECIPE_PREVIEW=true`. Production remains the default when no Dart defines are supplied. The first account registered in this isolated preview project receives the owner role; later accounts receive customer role. This first-account rule is specific to this unshared test project and must never be copied to production.

Active publishable key for the preview app (safe for client-side use):
`sb_publishable_VSsRlb6ITGZrWa6oz70HsQ_mQkfJfJi`

From the repository root, build/run the preview variant:

```bash
flutter pub get
flutter run \
  --dart-define=RECIPE_PREVIEW=true \
  --dart-define=SUPABASE_URL=https://lpuzgzgyxqfwnwpfbefw.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_VSsRlb6ITGZrWa6oz70HsQ_mQkfJfJi
```

For iPhone installation, open `ios/Runner.xcworkspace` in Xcode, select the iPhone and a valid Apple development signing team, then run the same preview build. A signed iOS build requires the user's Apple signing identity.

The first registration may require email confirmation depending on the Auth email settings. After confirmation, sign in with the same test email/password. No production users or data are present in this project.

## Remaining before first real AI request

1. Add `GEMINI_API_KEY` as an Edge Function secret in this preview project. Do not add it to GitHub or Flutter.
2. Register the first preview user and sign in.
3. Build the preview app on the Mac and install it on the iPhone.
4. Test several photographed recipes, verify extraction, unit conversions, ingredient prices, TTK saving and cost per entered quantity.
