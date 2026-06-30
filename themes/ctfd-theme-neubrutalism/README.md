# Neubrutalism

A custom neubrutalism-style theme for CTFd. This theme is built upon the CTFd core-beta structure, utilizing Bootstrap 5, Alpine.js, and Vite for an improved and modern frontend experience with a distinct neubrutalist aesthetic.

## Installation

To install this theme in your CTFd instance, navigate to your CTFd `themes` directory and clone the repository:

```bash
cd CTFd/themes
git clone https://github.com/fami0110/ctfd-theme-neubrutalism.git neubrutalism
```

After cloning, you can select the `neubrutalism` theme from the CTFd Admin Panel under **Config > Themes**.

## IMPORTANT

Because this theme using jinja gadget from server at `page.html` to count the challeng, you need to add this gadget in `CTFd/utils/initialization/__init__.py` at `def init_template_globals(app)`:

```py
def get_challenge_count():
   from CTFd.utils.challenges import get_all_challenges

   return len(get_all_challenges())

app.jinja_env.globals.update(get_challenge_count=get_challenge_count)
```

## Development

If you want to modify or develop the theme further, follow these steps:

1. **Understand the structure**: The `./assets` folder contains the uncompiled source files (the ones you can modify), while the `./static` directory contains the compiled ones.
2. **Install Yarn**: Install [Yarn](https://classic.yarnpkg.com/en/) following the [official installation guides](https://classic.yarnpkg.com/en/docs/install).
   - **Yarn** is a dependency management tool used to install and manage project packages.
   - **[Vite](https://vite.dev/guide/)** handles the frontend tooling by building optimized assets.
3. **Install Dependencies**: Run `yarn install` in the root of the theme folder to install the necessary Node packages including `vite`.
4. **Run the build mode**:
   - Run `yarn dev` (this will run `vite build --watch`) while developing the theme. Vite allows you to preview changes instantly with hot reloading.
   - Run `yarn build` (which will run `vite build`) for a one-time build.
5. **Start Modifying**: You can start your modifications in the `assets` folder. Each time you save, Vite will automatically recompile everything (if using `yarn dev`), and you can directly see the result in your CTFd instance.
6. **Production Build**: When you are ready, you can use `yarn build` to build the production copy of your theme.

*Note: You do not need the `node_modules` folder in production, you can safely remove it or avoid zipping it if you are packaging the theme directory.*

## Preview

<img width="1856" height="1038" alt="Screenshot from 2026-05-11 01-59-32" src="https://github.com/user-attachments/assets/4cae1d63-7c71-472c-a221-224666e4d4c2" />
<br>
<img width="1856" height="1228" alt="Screenshot from 2026-05-11 02-01-00" src="https://github.com/user-attachments/assets/f1564eb5-18f9-4142-9458-2eb60feee222" />
<br>
<img width="1856" height="1183" alt="screencapture-127-0-0-1-8000-scoreboard-2026-05-11-02_03_26" src="https://github.com/user-attachments/assets/d753079a-4ed6-4a2e-82f5-7e90cfee3c93" />
