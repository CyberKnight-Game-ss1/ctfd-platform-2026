# Theme and Frontend Customizations

## Base Theme
The platform uses a custom theme named `ctfd-theme-neubrutalism`.

## Alpine.js vs Vanilla JS
- **The Problem:** The default CTFd theme heavily relies on Alpine.js (`x-data`). However, custom modifications and CTFd's internal script loading often conflict, causing Alpine directives to fail (e.g., buttons not clicking, forms not submitting).
- **The Solution:** For critical user flows, we strip out Alpine.js directives (`x-bind`, `@click`, `x-data`) and replace them with standard **Vanilla JavaScript** and **Bootstrap 5 Modals**.

### Modified Templates:
1. `teams/private.html`:
   - Replaced Alpine invite modal with Vanilla JS.
   - Used standard `fetch()` API calls to `/api/v1/teams/me/members`.
2. `settings.html`:
   - Rewrote profile update form to use Vanilla JS and `fetch()`.
3. `confirm.html` & `components/snackbar.html`:
   - Designed a full-screen, blocking modal that forces users to verify their email before navigating the site.
   - Removed Alpine dismissal logic.

## Rebranding
All mentions of "CTFd" or third-party platforms have been removed to ensure the platform feels fully internal.
- Navbar brand updated to "CyberKnight Core Team"
- Footer updated to "Internal Web Exploit CTF"
