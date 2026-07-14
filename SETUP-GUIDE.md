# Rev Nation Jaipur — Phase 2 Setup Guide

This covers wiring up Supabase (so the site and admin panel are live-connected) and exactly how to get your photos, videos, and frame sequences onto the site.

---

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → sign up (free) → **New Project**
2. Pick any name/region, set a database password (save it somewhere), wait ~2 minutes for it to spin up

## 2. Run the schema

1. In your project, open **SQL Editor** → **New query**
2. Paste the entire contents of `supabase-schema.sql` (included in this delivery)
3. Click **Run**

This creates all six tables (`services`, `projects`, `frame_sequences`, `testimonials`, `stats`, `leads`), sets up permissions so visitors can only read published content and submit the booking form, creates the three storage buckets (`project-images`, `frame-sequences`, `site-assets`), and seeds the stats/testimonials with the same numbers currently hardcoded on the site — so nothing changes visually the moment you connect it.

## 3. Get your API keys

In your Supabase project: **Project Settings → API**
- Copy the **Project URL**
- Copy the **anon public** key (not the `service_role` one — that one must never go in frontend code)

## 4. Connect the site

Open `config.js` and replace the two placeholder values:

```js
window.REV_NATION_CONFIG = {
  SUPABASE_URL: "https://your-project-ref.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."
};
```

Save it, keep it in the same folder as `index.html` and `admin.html`. That's the only file you need to edit — both the live site and the admin panel read from it.

Once this is filled in, reload `index.html`: stats, testimonials, and any projects you've added will now come from Supabase instead of the built-in placeholder content, and the booking form will save real leads. If `config.js` is ever wrong or Supabase is unreachable, the site silently falls back to its built-in placeholder content instead of breaking — you'll never show visitors a broken page.

## 5. Create your admin login

Supabase Auth needs at least one user to sign into `admin.html`:

1. **Authentication → Users → Add user**
2. Enter your email + a password, and toggle **Auto Confirm User** on (so you don't need to click an email link)
3. Open `admin.html` and sign in with those credentials

Anyone signed in through Supabase Auth has full access to the admin panel — don't share this login, and create separate users if more than one person needs access.

---

## 6. How to upload videos and images

### Project photos, before/after shots, testimonials
Use the **admin panel** (`admin.html`) — this is the easiest path:
- **Projects tab** → fill in the form, attach a cover photo, hit *Add Project*. It uploads to the `project-images` bucket and appears in the live "Recent Builds" gallery immediately.
- **Testimonials tab** → add reviews directly, no file upload needed.
- **Stats tab** → edit the odometer numbers directly.

### Frame sequences (the scroll-scrub canvas effect)
This is the one that needs a bit of prep work on your end before uploading:

1. **Shoot or render the sequence** — a turntable video works well; export it as a numbered image sequence (most editing tools, or `ffmpeg`, can do "export frame per file")
2. **Name files so they sort correctly** — `frame-0001.jpg`, `frame-0002.jpg`, etc. Zero-padded numbers matter; without padding, `frame-2.jpg` can sort after `frame-10.jpg` and scramble the sequence
3. **Compress before uploading** — aim for 60–120KB per frame (see the spec table in the animation plan doc). Large unoptimized frames will make the scroll effect feel sluggish regardless of how good the code is
4. Go to `admin.html` → **Frame Sequences tab**:
   - Pick a project (optional — leave blank for sequences not tied to a specific build)
   - Pick which scene it's for: Hero, PPF Signature Scene, or Mods Scene
   - Select all frame files at once (the panel sorts them numerically before uploading, so exact selection order doesn't matter)
   - Click **Upload Sequence** — it uploads one by one with a progress counter, then saves the sequence record

Once a sequence is uploaded, the actual site code that reads `frame_sequences` and draws it to canvas is the next build step I'll wire in — right now the admin panel gets the files into storage and recorded in the database, ready for that.

### The hero video specifically
Keep the hero video (`assets/hero-reveal.mp4`) as a regular file alongside `index.html`, the way it is now — **don't** route it through Supabase Storage. Reasoning:
- It's a single fixed asset, not something you'll swap frequently from the admin panel
- Video files eat through the 1GB free storage tier fast, and Supabase Storage isn't optimized for video streaming/transcoding the way a dedicated video CDN is
- If you later want a different or updated hero video, just replace the file in `assets/` directly — no database involved

If you eventually want visitors to *submit* videos, or want multiple video assets managed from the admin panel, that's worth a dedicated video host (Cloudflare Stream, Mux, or Bunny Stream) rather than Supabase Storage — happy to wire that in when you need it.

### Manual alternative (bulk work, or when the admin panel isn't handy)
You can always drag-and-drop files directly in **Supabase → Storage → [bucket name]** in your browser — useful for bulk-uploading a large frame sequence faster than one-by-one through the admin panel's file input. Just keep the folder structure consistent: `frame-sequences/{project-id or "general"}/{section}/frame-0001.jpg` — and if you upload this way, add the matching record manually in the `frame_sequences` table (**Table Editor** tab) so the site knows the sequence exists.

---

## 7. Storage budget reminder

You're on the Supabase **Free** tier (1GB storage) until you upgrade. Rough math:
- Project photos: ~200–400KB each after compression → hundreds fit easily
- One frame sequence (150 frames × ~90KB): ~13MB
- Three or four sequences plus a healthy project gallery will approach the 1GB ceiling

When you're ready to add the PPF and mods frame sequences for real, that's the moment to move to **Pro ($25/mo, 100GB)** — flagged in the original plan, still the right call.

---

## What's next

With this connected, the natural next steps are:
1. Wire the canvas frame-sequence player into `index.html` so uploaded sequences actually scroll-scrub (currently the hero/PPF scenes still use the SVG-based placeholders)
2. Add the `services` table to the admin panel so the six service items become editable too (currently only projects/testimonials/stats are dynamic)
3. Once real project photos and sequences are in, retire the placeholder SVG icons across the site

Send the word whenever you want me to take on any of these.
