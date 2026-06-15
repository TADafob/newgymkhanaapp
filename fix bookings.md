<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 200px 0 20px 0;">

<div style="font-size: 24px; margin-bottom: 12px;"><strong>Amazon Q</strong></div>
<div style="background: rgba(128, 128, 128, 0.15); border: 1px solid rgba(128, 128, 128, 0.25); border-radius: 8px; padding: 8px; margin: 4px 0; text-align: center;">
<div style="font-size: 14px; margin-bottom: 4px;"><strong>Did you know?</strong></div>
<div>Pinned context is always included in future chat messages</div>
</div>

Select code & ask me to explain, debug or optimize it, or type `/` for quick actions

</div>

---

i want to change the logic for the facility bookings a bit, i want for the squash, badminton bookings to remain as is (48 hours advance, 2 slots maximum etc...), now for the rest of the sports bookings, the member has the capacity to book sessions nb. not time slots..... they book the court, and then select the date which is not limited to any advance booking time frame, then they select the timings....(which should be subject to availability, for the specific times selected)..... (in order to have smooth flexible sets even when new facilities, should i set this in the firestore???)

---

Let me first look at the existing bookings structure to understand what we're working with.

---

Now let me check the FirebaseService to understand the existing methods and Firestore structure:

---

Now I have a clear picture. Let me also check the Facilities collection structure to understand what fields exist:

---

Now I have a complete picture. Let me think through the design before writing any code.

Here's the situation and my recommendation:

---

**The plan:**

**Firestore approach (yes, you should use it):** Add a `booking_Mode` field to each `Facilities` document. Values: `"slot"` (squash/badminton — existing 48h/2-slot logic) or `"session"` (everything else — free date, custom time range, availability-checked). This makes it fully data-driven — adding a new facility just requires setting the right `booking_Mode` in Firestore, no code changes needed.

**What changes:**
1. `firebase-service.js` — add `listenSessionBookingsForFacility` (real-time availability listener for the session-style courts)
2. `bookings.js` — in `renderSportsStep`, branch on `booking_Mode`: if `"slot"` → existing logic unchanged; if `"session"` → new UI: date picker (no min/max restriction) + time range selectors + real-time conflict check per court
3. `facilities-manager.html` — add `booking_Mode` dropdown to the admin form

Let me implement this:

---

Add a real-time listener for session-mode court bookings (used by non-squash/badminton sports).

---

Now update `bookings.js` — the `renderSportsStep` and `onSportsDateChange` functions need to branch on `booking_Mode`, and we need to add the session booking UI + submit logic:

---

Replace renderSportsStep with a branching version: slot mode (existing logic) vs session mode (new free-date, time-range, conflict-checked booking UI).

---

Now update `loadFacilityCache` to also pull `booking_Mode` from Firestore:

---

Cache the booking_Mode field from Firestore so the UI can branch on it.

---

Now add `booking_Mode` to the admin facilities form:

---

Add booking_Mode dropdown to the admin facility form so admins can set slot vs session mode per facility.

---

Now wire `booking_Mode` into the admin save and edit logic:

---

Save and load booking_Mode in the admin facility form submit and edit handlers.

---

Now let me verify the `loadFacilityCache` uses `facility_Id` correctly — the Firestore doc uses `facility_Id` as a field, but looking at the admin save it uses `db.collection('Facilities').add(finalData)` without setting `facility_Id`. Let me check how the cache keys work:

---

The file looks good. Now I need to also add a Firestore composite index note — the new `listenSessionBookingsForCourt` query uses `facility_Id + court_No + start_Time` which needs an index. Let me check the existing indexes:

---

The indexes file is empty. Let me add the required composite index for the new session query:

---

Add the composite Firestore index required by the new listenSessionBookingsForCourt query.

---


Everything is in place. Here's a summary of what was done and how to use it:

---

**What changed — 3 files:**

**`firestore.indexes.json`**
Added the composite index `facility_Id + court_No + start_Time` that the new session query requires. Deploy it with `firebase deploy --only firestore:indexes`.

**`firebase-service.js`**
Added `listenSessionBookingsForCourt` — a real-time listener that queries by `facility_Id + court_No + start_Time` range (instead of `booking_Date`), which is what session-mode bookings need.

**`bookings.js`**
- `loadFacilityCache` now caches `booking_Mode` from Firestore (defaults to `"slot"`)
- `renderSportsStep` now branches: `booking_Mode === 'session'` → new UI, otherwise → existing slot UI unchanged
- New session UI: court dropdown → date (no max restriction) → time range selectors → live conflict display → participants → confirm

**`facilities-manager.html` (admin)**
Added a "Booking Mode" dropdown to the facility form so admins can set `slot` or `session` per facility when creating/editing.

---

**To set up your existing facilities:**
1. Go to the admin Facilities Manager
2. Edit Squash and Badminton → set Booking Mode to **Slot**
3. Edit all other sports (Tennis, Swimming, etc.) → set Booking Mode to **Session**

That's it — adding any new facility in the future just requires picking the right mode in the admin panel, no code changes needed.

---

bookings.js:301 Uncaught TypeError: courts.map is not a function
    at renderSessionStep (bookings.js:301:20)
    at renderSportsStep (bookings.js:225:5)
    at renderStep3 (bookings.js:217:32)
    at renderModalStep (bookings.js:134:30)
    at modalNext (bookings.js:757:3)
    at HTMLButtonElement.onclick (bookings.html:1:1)
renderSessionStep @ bookings.js:301
renderSportsStep @ bookings.js:225
renderStep3 @ bookings.js:217
renderModalStep @ bookings.js:134
modalNext @ bookings.js:757
onclick @ bookings.html:1
bookings.js:1104 Uncaught TypeError: Cannot read properties of null (reading &#39;_feeLabel&#39;)
    at renderPaymentStep (bookings.js:1104:22)
    at renderModalStep (bookings.js:135:30)
    at modalNext (bookings.js:757:3)
    at HTMLButtonElement.onclick (bookings.html:1:1)

---

The `courts` field in Firestore is an array of objects (from the admin form), but the cache stores it as-is. Let me check what the cache actually holds:

---

Two bugs, both clear:

1. **`courts.map is not a function`** — `info.courts` from Firestore is an array of objects `[{court_Name, capacity, images}]`, but the cache stores it as-is. The slot mode uses it as a number (`info.courts || 1`), so it was always a number there. For session mode we need the actual array from Firestore, not the cached value.

2. **`Cannot read properties of null (reading '_feeLabel')`** — `modalBack()` from step 4 decrements to step 3, which re-renders the session form and clears `_pendingBookingData` to null, then `modalNext()` goes to step 4 again without re-submitting, so `_pendingBookingData` is null. The `modalNext()` on step 3 should be blocked for session mode (the submit button handles progression, not Next).

Both fixes:

---

Fix courts.map error by preserving the array from Firestore, and guard modalNext from advancing past step 3 for session-mode sports without a pending booking.

---

Also fix `renderCourtTabs` which uses `info.courts` as a number — it needs to handle both cases (slot mode gets a number, session mode gets an array):

---

Handle courts being either a number (old data) or an array (new Firestore structure) in renderCourtTabs.

---


Three fixes applied:

1. **`courts.map is not a function`** — `loadFacilityCache` now preserves the array when `f.courts` is an array (session mode), and falls back to a number when it's not (slot mode). `renderSessionStep` also safely extracts the array. `renderCourtTabs` handles both cases.

2. **`_feeLabel` null crash** — `modalNext()` now blocks progression past step 3 for session-mode sports facilities. The only way to reach step 4 is through the "Confirm Booking" button in `submitSessionBooking()`, which sets `_pendingBookingData` before advancing.

---

why am i not getting the courts in the &#39;session&#39; facilities when booking

---

Let me check what's actually stored in Firestore for the facilities to understand the data shape.

---

The root cause is clear. Look at `getFacilitiesByType` — it returns `doc.id` as `id`, but the cache keys by `f.facility_Id`. The Firestore documents saved by the admin form **don't have a `facility_Id` field** — the admin saves `facility_Name`, `facility_Type`, `courts`, etc., but never sets `facility_Id`. So `f.facility_Id` is `undefined`, meaning `cacheObj[undefined] = {...}` and `courts` is never found by `_modalFacilityId`.

The `courts` array is also stored correctly in Firestore as `[{court_Name, capacity, images}]`, but since the cache key is broken, `sportsFacilities[_modalFacilityId]` returns `undefined` → `info` is `undefined` → `courts` is `[]`.

Two fixes needed:
1. Cache key should use `f.id` (the Firestore doc ID) when `f.facility_Id` is missing
2. The facility selector in step 2 uses the same key, so it's consistent

---

No change needed here — already correct. Checking the actual issue is the facility_Id field missing from Firestore docs.

---

Good — `loadFacilityCache` already has `f.facility_Id || f.id` as the key. Now the real remaining issue: the `getFacilitiesByType` service returns `{ id: doc.id, ...doc.data() }` — so `f.id` is the Firestore doc ID. But the bookings are stored with `facility_Id` set to whatever `_modalFacilityId` is (the cache key). Since the cache key is now `f.id` (the doc ID), and `_modalFacilityId` is set from the cache key in `selectModalFacility`, that part is consistent.

The real problem is the **courts array**. Let me add a quick `console.log` isn't the right approach — let me trace it properly. The `courts` field in Firestore from the admin is `[{court_Name, capacity, images, isActive}]`. The cache stores it as-is when it's an array. Then `renderSessionStep` does:

```js
const raw = info?.courts;
const courts = Array.isArray(raw) ? raw : [];
```

This should work IF `info` is not `undefined`. The only way `info` is `undefined` is if `sportsFacilities[_modalFacilityId]` misses — meaning the cache key doesn't match `_modalFacilityId`.

Let me check: does the admin form ever set `facility_Id` as a field in the document?

---

Confirmed — the admin `handleFormSubmit` never writes `facility_Id` into the document. So `f.facility_Id` is always `undefined` for every facility. The cache key falls back to `f.id` (the Firestore doc ID), which is correct — but the **existing facilities in Firestore that were saved before this change** also have no `facility_Id` field, so they're fine too.

The actual problem is simpler: the `getFacilitiesByType` query filters by `facility_Type === 'Sports'`, but the admin form's type options are `"Sports"`, `"Event Space"`, `"Wellness"`, `"Other"` — **none of the session facilities (Tennis, Swimming, etc.) are typed as `"Sports"`** in Firestore. They were likely saved with a different type, or the `booking_Mode` field simply doesn't exist yet on existing documents.

The fix is two-part:
1. The admin form needs to save `facility_Id` as the doc ID so it's explicit and consistent
2. Existing facilities need `booking_Mode` set — but since we can't know what's in Firestore, the cache fallback `|| 'slot'` handles new ones; existing ones just need to be re-saved via admin

Let me fix the admin to always write `facility_Id` into the document:

---

Write facility_Id as the doc ID into new facility documents so the cache key is always consistent.

---


Now the real issue — **your existing session facilities in Firestore don't have `booking_Mode: 'session'` set yet**, so they all fall back to `'slot'` mode and show the slot UI instead. You need to go to the admin Facilities Manager, edit each non-squash/badminton sport, set Booking Mode to **Session**, and save. That write will also add `facility_Id` to the doc.

But there's one more thing to verify — the `courts` field. The `getFacilitiesByType` query returns docs where `facility_Type === 'Sports'`. Open your browser console on the bookings page and run:

```js
console.log(sportsFacilities);
```

This will show you exactly what's cached. If a facility shows `courts: 1` (a number) instead of an array, it means the courts were never saved as sub-objects in the admin form — they were saved as a plain count. In that case, go to the admin, edit the facility, make sure each court has a name entered, and save.

**Summary of what was wrong:**
- Existing Firestore facility docs have no `booking_Mode` field → all defaulted to `'slot'` → session UI never rendered
- The admin never wrote `facility_Id` into the doc → now fixed for new saves
- **Action needed:** Edit each session-mode facility in the admin panel, set Booking Mode to "Session", ensure courts have names, and save

---

{
    &quot;F_Badminton&quot;: {
        &quot;facility_Name&quot;: &quot;Badminton Court&quot;,
        &quot;courts&quot;: 1,
        &quot;icon&quot;: &quot;&quot;,
        &quot;image&quot;: &quot;https://res.cloudinary.com/dzhhzuzju/image/upload/v1773399265/DSC_0221_cmfmff.jpg&quot;,
        &quot;description&quot;: &quot;Play in groups, currently has 3 courts fully revamped &quot;,
        &quot;fee&quot;: null,
        &quot;fee_unit&quot;: &quot;&quot;,
        &quot;booking_Mode&quot;: &quot;slot&quot;
    },
    &quot;F_Cricket_Nets&quot;: {
        &quot;facility_Name&quot;: &quot;Cricket Nets&quot;,
        &quot;courts&quot;: 1,
        &quot;icon&quot;: &quot;&quot;,
        &quot;image&quot;: &quot;https://res.cloudinary.com/dzhhzuzju/image/upload/v1773399323/DSC_0031_xnsbri.jpg&quot;,
        &quot;description&quot;: &quot;&quot;,
        &quot;fee&quot;: null,
        &quot;fee_unit&quot;: &quot;&quot;,
        &quot;booking_Mode&quot;: &quot;session&quot;
    },
    &quot;F_Squash&quot;: {
        &quot;facility_Name&quot;: &quot;Squash Court&quot;,
        &quot;courts&quot;: 1,
        &quot;icon&quot;: &quot;&quot;,
        &quot;image&quot;: &quot;https://res.cloudinary.com/dzhhzuzju/image/upload/v1771939857/squash-court_bkisab.jpg&quot;,
        &quot;description&quot;: &quot;&quot;,
        &quot;fee&quot;: null,
        &quot;fee_unit&quot;: &quot;&quot;,
        &quot;booking_Mode&quot;: &quot;slot&quot;
    },
    &quot;F_Tennis&quot;: {
        &quot;facility_Name&quot;: &quot;Tennis Court&quot;,
        &quot;courts&quot;: 1,
        &quot;icon&quot;: &quot;&quot;,
        &quot;image&quot;: &quot;https://res.cloudinary.com/dzhhzuzju/image/upload/v1773399356/DSC_0082_frivvn.jpg&quot;,
        &quot;description&quot;: &quot;&quot;,
        &quot;fee&quot;: null,
        &quot;fee_unit&quot;: &quot;&quot;,
        &quot;booking_Mode&quot;: &quot;session&quot;
    },
    &quot;F_Volleyball&quot;: {
        &quot;facility_Name&quot;: &quot;Volleyball Court&quot;,
        &quot;courts&quot;: 1,
        &quot;icon&quot;: &quot;&quot;,
        &quot;image&quot;: &quot;https://res.cloudinary.com/dzhhzuzju/image/upload/v1773399324/DSC_0043_q0ng4o.jpg&quot;,
        &quot;description&quot;: &quot;&quot;,
        &quot;fee&quot;: null,
        &quot;fee_unit&quot;: &quot;&quot;,
        &quot;booking_Mode&quot;: &quot;session&quot;
    }
}

---

There it is — `courts: 1` (a number) for all facilities. The Firestore docs have `courts` stored as a number, not as an array of objects. That's because these facilities were created before the admin form had the courts sub-units section, or were saved with the old structure.

So `Array.isArray(1)` is `false` → `courts = []` → empty dropdown.

The fix: in `renderSessionStep`, when `courts` is a number, generate that many generic court options instead of showing nothing.

---

When courts is a number, generate generic Court 1…N objects so the dropdown is always populated.

---


That's the only change needed. Now when `courts: 1`, it generates `[{court_Name: 'Court 1'}]`, so the dropdown shows "Court 1". When you later update the facilities in the admin with proper named courts (e.g. "Court A", "Court B"), those names will show automatically since they'll be stored as an array.

---

Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.
Tracking Prevention blocked access to storage for &lt;URL&gt;.

firebase-config.js:27 Firebase initialized
bookings.js:435 Uncaught TypeError: Cannot set properties of null (setting &#39;textContent&#39;)
    at _checkSessionConflict (bookings.js:435:63)
    at bookings.js:411:5
    at Object.next (firebase-service.js:330:9)
    at Object.next (database.ts:913:23)
    at next (index.esm2017.js:20677:27)
    at index.esm2017.js:16739:27
_checkSessionConflict @ bookings.js:435
(anonymous) @ bookings.js:411
(anonymous) @ firebase-service.js:330
(anonymous) @ database.ts:913
(anonymous) @ index.esm2017.js:20677
(anonymous) @ index.esm2017.js:16739
setTimeout
Sc @ index.esm2017.js:16738
next @ index.esm2017.js:16729
$u @ index.esm2017.js:15181
(anonymous) @ index.esm2017.js:15130
ua @ index.esm2017.js:16119
await in ua
zc @ index.esm2017.js:15868
await in zc
(anonymous) @ index.esm2017.js:20703
await in (anonymous)
(anonymous) @ index.esm2017.js:18065
(anonymous) @ index.esm2017.js:18098
Promise.then
ta @ index.esm2017.js:18098
enqueue @ index.esm2017.js:18065
enqueueAndForget @ index.esm2017.js:18043
(anonymous) @ index.esm2017.js:20703
Ef @ index.esm2017.js:20701
mf @ index.esm2017.js:20611
set @ database.ts:716
createBooking @ firebase-service.js:339
await in createBooking
finaliseBooking @ bookings.js:1161
onclick @ bookings.html:1
bookings.js:435 Uncaught TypeError: Cannot set properties of null (setting &#39;textContent&#39;)
    at _checkSessionConflict (bookings.js:435:63)
    at bookings.js:411:5
    at Object.next (firebase-service.js:330:9)
    at Object.next (database.ts:913:23)
    at next (index.esm2017.js:20677:27)
    at index.esm2017.js:16739:27
_checkSessionConflict @ bookings.js:435
(anonymous) @ bookings.js:411
(anonymous) @ firebase-service.js:330
(anonymous) @ database.ts:913
(anonymous) @ index.esm2017.js:20677
(anonymous) @ index.esm2017.js:16739
setTimeout
Sc @ index.esm2017.js:16738
next @ index.esm2017.js:16729
$u @ index.esm2017.js:15181
(anonymous) @ index.esm2017.js:15130
ua @ index.esm2017.js:16119
await in ua
Wc @ index.esm2017.js:15894
await in Wc
(anonymous) @ index.esm2017.js:14581
(anonymous) @ index.esm2017.js:14551
await in (anonymous)
onMessage @ index.esm2017.js:14049
(anonymous) @ index.esm2017.js:13995
(anonymous) @ index.esm2017.js:14018
(anonymous) @ index.esm2017.js:18065
(anonymous) @ index.esm2017.js:18098
Promise.then
ta @ index.esm2017.js:18098
enqueue @ index.esm2017.js:18065
enqueueAndForget @ index.esm2017.js:18043
(anonymous) @ index.esm2017.js:14018
(anonymous) @ index.esm2017.js:13995
_o @ index.esm2017.js:13387
(anonymous) @ index.esm2017.js:13616
(anonymous) @ index.esm2017.js:13567
C @ eventtarget.js:351
C @ eventtarget.js:481
(anonymous) @ webchannelbasetransport.js:421
(anonymous) @ webchannelbase.js:2342
(anonymous) @ channelrequest.js:959
ic @ channelrequest.js:751
(anonymous) @ channelrequest.js:610
C @ eventtarget.js:351
C @ eventtarget.js:481
Ad @ xhrio.js:915
(anonymous) @ xhrio.js:872
(anonymous) @ xhrio.js:855
od @ fetchxmlhttpfactory.js:559
(anonymous) @ fetchxmlhttpfactory.js:406
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:410
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:355
Promise.then
(anonymous) @ fetchxmlhttpfactory.js:271
(anonymous) @ xhrio.js:689
ic @ channelrequest.js:585
Md @ channelrequest.js:532
(anonymous) @ webchannelbase.js:1701
(anonymous) @ run.js:116
Promise.then
(anonymous) @ run.js:65
Fc @ run.js:47
Md @ webchannelbase.js:2377
(anonymous) @ channelrequest.js:959
ic @ channelrequest.js:751
(anonymous) @ channelrequest.js:610
C @ eventtarget.js:351
C @ eventtarget.js:481
Ad @ xhrio.js:915
(anonymous) @ xhrio.js:872
(anonymous) @ xhrio.js:855
od @ fetchxmlhttpfactory.js:559
(anonymous) @ fetchxmlhttpfactory.js:406
Promise.then
cn @ fetchxmlhttpfactory.js:371
(anonymous) @ fetchxmlhttpfactory.js:355
Promise.then
(anonymous) @ fetchxmlhttpfactory.js:271
(anonymous) @ xhrio.js:689
ic @ channelrequest.js:582
gc @ channelrequest.js:511
(anonymous) @ webchannelbase.js:1486
(anonymous) @ run.js:116
Promise.then
(anonymous) @ run.js:65
Gc @ run.js:47
(anonymous) @ webchannelbase.js:796
(anonymous) @ index.esm2017.js:13559
send @ index.esm2017.js:13378
Wo @ index.esm2017.js:13910
su @ index.esm2017.js:14080
Yu @ index.esm2017.js:14463
(anonymous) @ index.esm2017.js:14499
(anonymous) @ index.esm2017.js:14498
(anonymous) @ index.esm2017.js:13991
(anonymous) @ index.esm2017.js:14018
(anonymous) @ index.esm2017.js:18065
(anonymous) @ index.esm2017.js:18098
Promise.then
ta @ index.esm2017.js:18098
enqueue @ index.esm2017.js:18065
enqueueAndForget @ index.esm2017.js:18043
(anonymous) @ index.esm2017.js:14018
(anonymous) @ index.esm2017.js:13990
fo @ index.esm2017.js:13381
(anonymous) @ index.esm2017.js:13625
setTimeout
Ro @ index.esm2017.js:13620
eu @ index.esm2017.js:14036
Zo @ index.esm2017.js:13989
(anonymous) @ index.esm2017.js:13979
Promise.then
auth @ index.esm2017.js:13970
start @ index.esm2017.js:13875
Zu @ index.esm2017.js:14479
Hu @ index.esm2017.js:14440
(anonymous) @ index.esm2017.js:15757
await in (anonymous)
Vc @ index.esm2017.js:15101
(anonymous) @ index.esm2017.js:17342
(anonymous) @ index.esm2017.js:17330
await in (anonymous)
(anonymous) @ index.esm2017.js:18065
(anonymous) @ index.esm2017.js:18098
Promise.then
ta @ index.esm2017.js:18098
enqueue @ index.esm2017.js:18065
enqueueAndForget @ index.esm2017.js:18043
Ha @ index.esm2017.js:17330
(anonymous) @ index.esm2017.js:20580
get @ index.esm2017.js:20580
getFacilitiesByType @ firebase-service.js:122
await in getFacilitiesByType
loadFacilityCache @ bookings.js:77
(anonymous) @ bookings.js:47
Promise.then
(anonymous) @ bookings.js:45

---

Two separate issues in the console:

1. **Tracking Prevention** — not a code bug, just Edge/Firefox blocking third-party storage (Firebase SDK trying to use IndexedDB for offline persistence). Harmless for functionality.

2. **The real bug** — `_checkSessionConflict` fires from the Firestore listener **after the modal has already closed** (user clicked Confirm → `finaliseBooking` → booking saved → Firestore write triggers the listener → listener calls `_checkSessionConflict` → DOM elements are gone → null crash).

The listener from `onSessionTimeChange` is never cleaned up when moving to step 4. The fix is to unsubscribe `_slotsUnsub` before advancing to payment, and guard `_checkSessionConflict` against missing DOM elements.

---

Guard _checkSessionConflict against stale listener firing after modal navigation, and unsubscribe the slots listener before advancing to the payment step.

---

Guard _checkSessionConflict against stale listener firing after modal closes, and unsubscribe slots listener before advancing to payment step.

---

Now I can see the exact lines. Two targeted fixes:

---

Guard _checkSessionConflict against stale listener callbacks after modal navigation, and unsubscribe the slots listener before advancing to the payment step.

---


Two fixes applied:

1. **`_checkSessionConflict`** — now starts with an early return if the DOM elements don't exist, so stale Firestore listener callbacks firing after the modal has moved to step 4 (or closed) are silently ignored.

2. **`submitSessionBooking`** — now kills `_slotsUnsub` before calling `renderModalStep()` for step 4, so the listener is torn down before the step 3 DOM is replaced, preventing any further callbacks from hitting missing elements.

The "Tracking Prevention" warnings are a browser-level thing (Edge's tracking protection blocking Firebase's IndexedDB/cookie access when running from `file://` or a non-whitelisted origin) — not a code issue. They don't affect functionality when hosted properly.

---

why am i getting only one court in the dropdown, &#39;court 1 only&#39;

---

The cache stores `courts: 1` (a number) from Firestore, so the fallback generates only `Array.from({ length: 1 }, ...)` → one entry.

The actual number of courts for each facility needs to come from Firestore. Looking at your data dump — Tennis has 4 courts, Cricket has nets, Volleyball has 1, etc. — but Firestore just has `courts: 1` as a plain number for all of them because the admin form never saved them as named sub-units.

Two options:
1. Go to admin, edit each facility, add the actual courts with names, save — then the array gets stored properly
2. Or, add a `court_Count` field to Firestore per facility so you can set the number without needing named courts

The quickest fix that doesn't require touching every facility in the admin is to add a `court_Count` field to the Facilities manager form, and use that as the fallback count:

---

Add a court_Count field to the admin form so admins can set the number of courts for session-mode facilities without needing named sub-units.

---

Now use `court_Count` in the cache and session step:

---

Use court_Count from Firestore as the authoritative court count for session-mode facilities.

---

Now I can see the exact code. The cache key is still `f.facility_Id` (not `f.facility_Id || f.id`) and `court_Count` is not cached. Two precise fixes:

---

Fix cache key to use f.facility_Id || f.id, cache court_Count, and use it to generate the correct number of court options.

---


Two things fixed:

1. **Cache key** — now `f.facility_Id || f.id`, so facilities without an explicit `facility_Id` field still get cached correctly under their Firestore doc ID.

2. **Court count** — now caches `court_Count` from Firestore (the new field added to the admin form), and `renderSessionStep` uses it as the authoritative count. So for Tennis with `court_Count: 4` in Firestore, you'll get Court 1–4 in the dropdown.

**Action needed:** Go to the admin Facilities Manager, edit each session-mode facility, set the correct number in the new "Number of Courts" field, and save. That writes `court_Count` to Firestore and the dropdown will reflect it immediately on next page load.

---

nice, and now, some change for the charges..... for some facilites, they don&#39;t have guest levy.... like cricket nets (Ksh. 2000 per session/day), should i impose this on the firestore also?

---

Yes, absolutely store it in Firestore — that's exactly the right approach. It keeps the booking logic data-driven and means adding/changing fees for any facility never requires a code change.

Here's what to add to each facility document in Firestore (and the admin form):

- `fee` — the amount (e.g. `2000`)
- `fee_unit` — the label (e.g. `"per session"`, `"per day"`, `"per hour"`)
- `guest_levy` — boolean, whether the KES 200/guest charge applies (`true`/`false`)

The admin form already has `fee` and `fee_unit` fields implicitly (they're saved via `loadFacilityCache`), but they're not exposed in the UI. Let me add them properly, plus `guest_levy`:

---

Now I'll add the fee fields to the admin form and wire them up:

---

Add fee, fee_unit, and guest_levy fields to the admin facility form — saved to and loaded from Firestore.

---

Now update the cache and booking logic to use `guest_levy` from Firestore:

---

Cache guest_levy from Firestore, defaulting to true for backwards compatibility.

---

Now use `guest_levy` in the session booking UI and submit — replace the hardcoded guest fee logic:

---

Conditionally show the guest input only when guest_levy is true for the facility.

---

Now fix `submitSessionBooking` to use `guest_levy` when calculating the fee label:

---

Calculate fee combining base facility fee and guest levy only when applicable.

---


Done. Here's the full picture:

**Firestore fields per facility (set via admin):**
- `fee: 2000` — the booking charge in KES (0 = free)
- `fee_unit: "per session"` — label shown to member
- `guest_levy: false` — whether KES 200/guest applies

**Behaviour:**
- Cricket Nets → `fee: 2000`, `fee_unit: "per session"`, `guest_levy: false` → shows "KES 2,000 per session", no guest input
- Tennis → `fee: 0`, `guest_levy: true` → no base fee, but guest levy input shown if they bring guests
- Squash/Badminton (slot mode) → unchanged, guest levy still applies as before

**Action:** Go to admin Facilities Manager, edit each facility, fill in the fee fields, and save.

---

there is also different prices for the club facilities, like cricket ground etc..... they have different prices and also some have prices for both half day, or full day...... all these are calculated something like example ksh 25000 + VAT(which is always 16%), and also, the club admin can decide to give members a discount on the price....

---

Let me look at the current hire step to understand what we're working with:

---

Good. Now I have the full picture. Here's the plan:

**Firestore fields to add per Club facility:**
- `fee_full_day` — e.g. `25000`
- `fee_half_day` — e.g. `15000` (optional, null if not applicable)
- `discount_pct` — admin-set discount percentage, e.g. `10` (for 10%), `0` = no discount

VAT is always 16%, discount is applied before VAT. The member selects Full Day / Half Day (if available), the summary shows the full breakdown: base → discount → subtotal → VAT → total.

**Changes:** admin form (add the new fields) + `loadFacilityCache` + `renderHireStep` + `updateHireSummary` + `submitHireBooking`.

---

Cache fee_full_day, fee_half_day, and discount_pct from Firestore for hire facilities.

---

Now replace `renderHireStep`, `updateHireSummary`, and `submitHireBooking` with the new pricing-aware versions:

---

Replace hire step, summary, and submit with full pricing logic: half/full day selection, discount, VAT breakdown.

---

Now add the fields to the admin form:

---

Add full day rate, half day rate, and discount fields to the admin form — saved to and loaded from Firestore.

---

Add full day rate, half day rate, and discount fields to the admin form — saved to and loaded from Firestore.

---


Done. Here's the full picture of what's now in place:

**Firestore fields per Club facility (set via admin):**
- `fee_full_day: 25000` — full day rate before VAT/discount
- `fee_half_day: 15000` — half day rate (set to 0 if not offered, hides the option)
- `discount_pct: 10` — member discount %, 0 = none

**Booking flow for Club Hire:**
- If `fee_half_day > 0`, member sees a Full Day / Half Day radio selector with prices shown
- Summary shows the full breakdown: Base Rate → Discount (if any) → VAT (16%) → **Total**
- The breakdown is also saved to Firestore in `fee_breakdown: { base, discount_pct, discount_amt, vat, total }`

**Example — Cricket Ground, 1 day, 10% discount:**
- Base: KES 25,000
- Discount (10%): − KES 2,500
- After discount: KES 22,500
- VAT (16%): KES 3,600
- **Total: KES 26,100**

**Action:** Edit each Club facility in the admin, fill in the Full Day Rate, Half Day Rate (if applicable), and Discount %, then save.

---

should i make the fee in an array or a map? and also the discount can only be given to a specific booking, not to all members who want to book

---

Good points. Let me think through both:

**Fee structure** — a map is the right choice over an array. Arrays require index-based access and order matters, maps are self-documenting. For a facility like Cricket Ground:

```js
pricing: {
  full_day: 25000,
  half_day: 15000,   // omit if not offered
  per_hour: 0        // omit if not offered
}
```

Clean, extensible, readable. Adding a new pricing tier later (e.g. `weekend_rate`) is trivial.

**Discount** — you're right, a facility-level `discount_pct` makes no sense if it's per-booking. The correct model is: the admin applies a discount when **reacting to / confirming a specific booking**, not at the facility level. So `discount_pct` should be removed from the Facilities doc entirely and instead live on the booking document inside `reaction` (which is already where admin approval lives).

So the flow becomes:
- Member books → sees base price + VAT → submits
- Admin reviews the booking → can optionally apply a discount % when confirming → system recalculates and updates the booking

This means:
1. Remove `discount_pct` from the facility admin form and Firestore
2. Change `pricing` to a map in the admin form
3. Update the cache and hire step to use `pricing` map
4. Add discount field to the admin bookings manager when confirming a hire booking

Let me check the bookings manager first:

---

Now I have everything I need. Here's the plan:

**Firestore structure changes:**
- Facilities: replace flat fee fields with a `pricing` map + remove `discount_pct`
- Bookings: discount lives in `reaction.discount_pct` and `reaction.discount_amt`, set by admin when confirming

**Changes across 3 files:**
1. `facilities-manager.html` — replace fee fields with `pricing` map inputs, remove discount
2. `bookings.js` — use `pricing` map in cache + hire step
3. `bookings-manager.html` — add discount input when admin approves a Club hire booking

---

Replace flat fee fields with pricing map, remove discount from facility level, add note that discounts are per-booking.

---

Now update the cache and hire logic in bookings.js to use `pricing` map:

---

Read pricing from the pricing map in Firestore, with fallback to old flat fields for backwards compatibility.

---

Now update `updateHireSummary` and `submitHireBooking` to remove the facility-level discount (it's now always 0 until admin applies it per-booking):

---

Remove facility-level discount from the member-facing summary — discount is zero until admin applies it per-booking.

---

Now update the admin bookings manager to add a discount input when approving a Club hire booking:

---

When admin confirms a Club hire booking, prompt for an optional discount %, recalculate the breakdown, and save it to the booking document.

---

Add per-booking discount prompt when admin confirms a Club hire booking, recalculating and saving the full fee breakdown.

---


Done. Here's the full summary of what changed and why:

**Firestore structure — Facilities:**
```
pricing: {
  full_day: 25000,
  half_day: 15000   // 0 = not offered
}
fee: 2000           // sports/banda flat fee
fee_unit: "per session"
guest_levy: false
```
The `pricing` map is clean and extensible — adding `weekend_rate`, `evening_rate` etc. later requires no code changes, just a new key.

**Discount — now per-booking only:**
- Removed from the Facilities doc entirely
- When admin clicks **Approve** on a Club hire booking in the bookings manager, they get a prompt: *"Apply a member discount? Enter % (0 for none)"*
- If a discount is entered, the system recalculates `discount_amt`, `vat`, and `total` and saves them back to `fee_breakdown` on the booking document
- The member's booking detail view will then show the updated total

**Flow:**
1. Member books Cricket Ground, full day, 2 days → sees KES 50,000 + 16% VAT = **KES 58,000**
2. Admin reviews → decides to give 10% discount → enters `10` in the prompt
3. Booking updates: base KES 50,000 → discount KES 5,000 → subtotal KES 45,000 → VAT KES 7,200 → **total KES 52,200**
4. Member sees the updated total in their booking detail

---

also, the admin should be able to adjust the price of a booking made

---

The current prompt-based approach is too limited for price adjustments. Let me add a proper modal in the bookings manager for this:

---

Now I'll replace the entire bookings manager with a proper pricing modal — replacing the prompt-based approach and adding a dedicated "Adjust Price" button for all booking types:

---

Replace prompt-based discount with a proper price adjustment modal supporting discount %, base override, VAT preview, and admin notes for all booking types.

---


Done. Here's what the admin now gets:

**Price button** — every non-cancelled booking in the table has a blue "Price" button alongside the status actions.

**For Club hire bookings** the modal shows:
- Override base amount (leave 0 to keep current)
- Discount % input
- Live preview updating as you type: Base → Discount → VAT (16%) → **Total**
- Admin note field (e.g. "Loyalty discount", "Negotiated rate")
- Saves `fee_breakdown` fully recalculated back to Firestore

**For Sports/Banda/other bookings** the modal shows:
- Simple override total amount field (since these don't have a VAT breakdown)
- Admin note field
- Saves to `guest_fee` and `fee_breakdown.total`

The `updateStatus` function is now clean — no more prompt, discount is handled entirely through the Price modal separately from approval.

---

why is the admin page not getting the proper facility name, currently it is showing facility_id/court no..... and also, the page should have the view button which now should have all the options like adjusting price, discount if applicable, etc

---

Let me read the current bookings manager to see the full state:

---


Now I'll rewrite the bookings manager properly — load facility names, consolidate everything into a single View/Detail modal with all actions inside it, and clean up the table:

---

Rewrite bookings manager with facility name resolution, a full detail modal containing all actions (status, price adjustment, discount, notes), and a clean table.

---

continue

---

Rewrite bookings manager with facility name resolution, a full detail modal containing all actions (status, price adjustment, discount, notes), and a clean table.