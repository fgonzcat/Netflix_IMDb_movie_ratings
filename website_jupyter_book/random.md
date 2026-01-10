---
html_theme:
  navigation_depth: 0
---

<script>
  const categories = [
    "horror",
    "comedy",
    "cult_movies",
    "documentaries",
    "action",
    "romance"
  ];

  const pick = categories[Math.floor(Math.random() * categories.length)];
  window.location.href = pick + ".html";
</script>

Picking a movie category for you…

