# Google Places Service Update - Search Modes

**Date**: 2025-02-04
**File**: `anigmaa/lib/core/services/google_places_service.dart`

---

## Summary

Updated the Google Places service to support **two distinct search modes**:

1. **Manual Search (Global)** - User typing, no location constraint
2. **Nearby Search (Location-based)** - Auto-load places within 50km radius

---

## Changes Made

### 1. Updated `searchPlaces()` Method

**Before**: Only filtered by popularity when location was provided

**After**: Filters by popularity for BOTH search modes, with different thresholds:

```dart
Future<List<GooglePlace>> searchPlaces({
  required String query,
  double? latitude,    // Optional location
  double? longitude,   // Optional location
}) async {
  // Route to appropriate search method
  final predictions = latitude != null && longitude != null
      ? await autocompleteNearby(...)  // With location → 50km radius
      : await autocomplete(...);       // Without location → global

  // Apply popularity filtering for BOTH modes
  final isNearby = latitude != null && longitude != null;
  final popularPlaces = await _filterByPopularity(places, isNearby: isNearby);
}
```

### 2. Enhanced `_filterByPopularity()` Method

**Before**: Fixed thresholds (4.0+ rating, 100+ reviews) for all searches

**After**: Adaptive thresholds based on search mode:

| Search Mode | Min Rating | Min Reviews | Rationale |
|-------------|------------|-------------|-----------|
| **Global** (manual) | 4.0 | 100 | Stricter - only show famous/landmark places |
| **Nearby** (auto) | 3.5 | 50 | More lenient - already filtered by place types |

```dart
Future<List<GooglePlace>> _filterByPopularity(
  List<GooglePlace> places,
  {bool isNearby = false}
) async {
  final minRating = isNearby ? 3.5 : 4.0;
  final minReviews = isNearby ? 50 : 100;
  // ... filtering logic
}
```

### 3. Updated Documentation

Enhanced docstrings for clarity:

- **`autocomplete()`** - Clarified as GLOBAL search (no radius limit)
- **`autocompleteNearby()`** - Clarified as NEARBY search (50km with strictbounds)
- **`searchPlaces()`** - Added usage examples for both modes

---

## Usage Examples

### Manual Search (Global)

User wants to find famous landmarks anywhere in Indonesia:

```dart
final places = await googlePlacesService.searchPlaces(
  query: "Monas",
  // No location provided = GLOBAL search
  // Can find Monas in Jakarta even if user is in Bali
  // Filter: 4.0+ rating, 100+ reviews
);
```

**Result**: Returns famous places matching "Monas" across Indonesia

### Nearby Search (Location-based)

App auto-loads places around user's location:

```dart
final places = await googlePlacesService.searchPlaces(
  query: "restoran",
  latitude: -7.55,   // User's location (Yogyakarta)
  longitude: 110.83,
  // With location = NEARBY search (50km radius)
  // Filter: popular types + 3.5+ rating, 50+ reviews
);
```

**Result**: Returns restaurants within 50km of Yogyakarta only

---

## Search Mode Comparison

| Feature | Manual Search (Global) | Nearby Search (Location-based) |
|---------|------------------------|--------------------------------|
| **Trigger** | User types in search box | App auto-loads nearby places |
| **Location** | Not provided | Required (lat/lng) |
| **Radius** | None (country-wide) | 50km with `strictbounds` |
| **API Method** | `autocomplete()` | `autocompleteNearby()` |
| **Type Filter** | None | Popular types only |
| **Rating Filter** | 4.0+, 100+ reviews | 3.5+, 50+ reviews |
| **Use Case** | Find famous landmarks | Discover nearby events |

---

## API Call Details

### Global Search (`autocomplete`)

```
GET /maps/api/place/autocomplete/json
Parameters:
  - input: "Monas"
  - components: "country:id"
  - language: "id"
  - NO location/radius/strictbounds
```

### Nearby Search (`autocompleteNearby`)

```
GET /maps/api/place/autocomplete/json
Parameters:
  - input: "restoran"
  - location: "-7.55,110.83"
  - radius: "50000" (50km)
  - strictbounds: "true"
  - components: "country:id"
  - language: "id"
```

---

## Benefits

1. **Better UX for manual search**: Users can find famous places regardless of their location
2. **Relevant nearby results**: Auto-load shows only local places, not irrelevant landmarks
3. **Flexible quality control**: Stricter filters for global, lenient for nearby
4. **Clear intent**: Two distinct modes with clear use cases

---

## Testing Checklist

- [ ] Manual search finds famous landmarks (Monas, Borobudur, Bali beaches)
- [ ] Nearby search only returns places within 50km
- [ ] Rating filters apply correctly for both modes
- [ ] No results returned when no places match criteria
- [ ] Logs show correct search mode (global vs nearby)

---

## Files Modified

- `anigmaa/lib/core/services/google_places_service.dart`

## Files Created

- `BLUEPRINT/PLACES_SEARCH_UPDATE.md` (this file)

---

**Status**: ✅ Complete
**Verified**: Flutter analyze passes
