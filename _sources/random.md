---
html_theme:
  navigation_depth: 0
orphan: true
---


<script>
  const categories = [
    "horror",
    "comedy",
    "cult",
    "crime_documentaries",
    "action_thrillers",
    "scifi"
  ];

  const pick = categories[Math.floor(Math.random() * categories.length)];
  window.location.href = pick + ".html";
</script>

Picking a movie category for you…

