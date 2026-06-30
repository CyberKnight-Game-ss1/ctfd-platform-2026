const SERIES_TONE_TOKENS = [
  "--ctfd-chart-tone-1",
  "--ctfd-chart-tone-2",
  "--ctfd-chart-tone-3",
  "--ctfd-chart-tone-4",
  "--ctfd-chart-tone-5",
  "--ctfd-chart-tone-6",
];

const SERIES_TONE_FALLBACKS = [
  "#ff9062",
  "#f4c46d",
  "#b8d67d",
  "#f2a78f",
  "#d6a85a",
  "#89a95f",
];

function getRootStyles() {
  return getComputedStyle(document.documentElement);
}

export function getThemeColor(token, fallback) {
  return getRootStyles().getPropertyValue(token).trim() || fallback;
}

export function getThemeSeriesPalette() {
  return SERIES_TONE_TOKENS.map((token, index) => {
    return getThemeColor(token, SERIES_TONE_FALLBACKS[index]);
  });
}

export function getThemeSeriesColor(index) {
  const palette = getThemeSeriesPalette();
  return palette[index % palette.length];
}

export function getThemeStatColors() {
  return {
    solve: getThemeColor("--ctfd-success", "#6f8c37"),
    fail: getThemeColor("--ctfd-danger", "#b9634f"),
  };
}

export function getThemeChartColors() {
  return {
    text: getThemeColor("--ctfd-chart-text", "#2c1913"),
    textSoft: getThemeColor("--ctfd-chart-text", "#2c1913"),
    textMuted: getThemeColor("--ctfd-chart-text-muted", "rgba(44, 25, 19, 0.74)"),
    surfaceHigh: getThemeColor("--ctfd-chart-surface", "#fff8f2"),
    surfaceBright: getThemeColor("--ctfd-chart-surface", "#fff8f2"),
    outline: getThemeColor("--ctfd-chart-outline", "rgba(44, 25, 19, 0.16)"),
    grid: getThemeColor("--ctfd-chart-grid", "rgba(44, 25, 19, 0.11)"),
    primary: getThemeColor("--ctfd-primary", "#d1713a"),
    fontBody: getThemeColor(
      "--ctfd-font-body",
      '"Manrope", "Lato", sans-serif',
    ),
  };
}
