const PROFILE_CATEGORY_TONES = [
  "profile-category-tone-1",
  "profile-category-tone-2",
  "profile-category-tone-3",
  "profile-category-tone-4",
  "profile-category-tone-5",
  "profile-category-tone-6",
];

export function getPercentage(part, total) {
  if (total === 0) {
    return "0.00";
  }

  return ((part / total) * 100).toFixed(2);
}

export function buildCategoryBreakdown(solves) {
  const categories = [];
  const breakdown = {};

  solves.forEach(solve => {
    categories.push(solve.challenge.category);
  });

  categories.forEach(category => {
    if (category in breakdown) {
      breakdown[category] += 1;
    } else {
      breakdown[category] = 1;
    }
  });

  return Object.keys(breakdown).map((name, index) => ({
    name,
    count: breakdown[name],
    percent: getPercentage(breakdown[name], categories.length),
    toneClass: PROFILE_CATEGORY_TONES[index % PROFILE_CATEGORY_TONES.length],
  }));
}
