# ZeRo Graphics — setup & deployment

This is a Vite + React portfolio with an admin UI and Supabase integration. The public portfolio and interface can be previewed locally immediately; persistent admin operations require a Supabase project and an explicitly authorized admin user. No password is embedded in the frontend.

## 1. Run locally

1. Install Node.js 20 or later.
2. Extract the project ZIP and open a terminal in the project folder.
3. Run `npm install` then `npm run dev`.
4. Open the local URL printed by Vite. `/admin` opens the private login screen.

## 2. Connect Supabase

1. Create a project at https://supabase.com.
2. Open **Project Settings → API** and copy the Project URL and publishable/anon key.
3. Copy `.env.example` to `.env` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
4. In Supabase **SQL Editor**, run all of `supabase/schema.sql`.
5. In **Authentication → Providers**, enable Email/password. Disable public sign-ups after creating your administrator.
6. Create an admin user through Supabase Auth (Dashboard → Authentication → Users → Add user). Choose a strong, unique password; do not reuse the sample credentials in the original brief.
7. Mark this user as an administrator. In Supabase SQL Editor, replace `ADMIN_USER_UUID_HERE` with that user's Auth UUID and run:

   ```sql
   update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"site_admin":"true"}'::jsonb
   where id = 'ADMIN_USER_UUID_HERE';
   ```

   This is required because RLS checks the signed JWT `app_metadata.site_admin` claim. Sign out and sign in again after changing the claim so a fresh token is issued.
8. Restart Vite after editing `.env`. Sign in at `/admin` using the admin email and password you created.

The SQL creates the tables, RLS policies and public image buckets. Public visitors can read published projects, visible services, published pricing, theme and public site settings. Only a signed-in user whose trusted `app_metadata.site_admin` claim is `true` can write content. Do not use user-editable `user_metadata` for admin authorization.

## 3. Deploy to Netlify

1. Push the project to a private/public Git repository you control, or deploy the project folder through Netlify.
2. In Netlify site settings → Environment variables, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
3. Build command: `npm run build`; publish directory: `dist` (already in `netlify.toml`).
4. Deploy. The Netlify redirects send `/admin` and client-side routes to the app shell.
5. Configure your domain and set the Supabase Auth Site URL and allowed redirect URLs to your deployed domain.

The Supabase anon/publishable key is intended for the browser; access is controlled by RLS. Never expose the service-role key or database password in a `VITE_` variable.

## 4. Important notes

- The uploaded portrait and logo reference are included in `public/assets`. The portrait source has a checkerboard-style backdrop baked into the image, so replace it with a clean transparent cutout if you have one. The logo reference image has white whitespace around the logo; upload a transparent PNG/SVG for a cleaner navbar logo. The original uploaded files are preserved.
- The initial portfolio art tiles are clearly labelled **demo concepts** and are not presented as real client work. Upload real designs in Admin → Portfolio Designs. Once actual records exist, the website displays them.
- Package prices are unset by default. Add real prices through Admin → Pricing; services can also be priced from the dashboard.
- Admin dashboard login is Supabase Auth, not the example username/password from the brief. This avoids exposing credentials in the frontend. Supabase Auth supplies secure session handling; keep sign-up closed after creating the admin account.
- The UI includes portfolio upload and delete, service edit/add, package add/edit/delete, theme settings, content settings, logo upload, social links and password update. This starter does not yet include a drag-and-drop ordering interface, image replacement flow for an existing portfolio record, or a separate draft toggle UI for portfolio records; those can be added next.
- Contact forms open WhatsApp with URL-encoded details. The website never claims a message was sent automatically.
- WhatsApp number is defined once in `src/App.jsx` as `WA`. If you change the number in dashboard content, update that constant too (or connect it to a server-side setting in a follow-up enhancement).
- Email is a placeholder until you change it to your real email.

## 5. Build check

Run `npm run build`. The generated production website is written to `dist/`.
