# Explore Netflix Titles

Choose your criteria and explore the full catalog.

<div id="controls">
  <label>Genre:
    <select id="genre"></select>
  </label>

  <label>Min IMDb rating:
    <input id="rating" type="number" step="0.1" value="7">
  </label>

  <label>Year from:
    <input id="yearFrom" type="number" value="2000">
  </label>

  <label>Year to:
    <input id="yearTo" type="number" value="2025">
  </label>
</div>

<div id="results"></div>

<script>
async function init() {
  const res = await fetch('_static/data/all_movies.json');
  const movies = await res.json();

  const genreSel = document.getElementById('genre');
  const genres = [...new Set(movies.map(m => m.genre))].sort();
  genreSel.innerHTML = `<option value="">All</option>` +
    genres.map(g => `<option value="${g}">${g}</option>`).join('');

  function render() {
    const g = genreSel.value;
    const r = parseFloat(document.getElementById('rating').value);
    const y0 = parseInt(document.getElementById('yearFrom').value);
    const y1 = parseInt(document.getElementById('yearTo').value);

    const filtered = movies.filter(m =>
      (!g || m.genre === g) &&
      (!m.imdb_rating || parseFloat(m.imdb_rating) >= r) &&
      parseInt(m.year) >= y0 &&
      parseInt(m.year) <= y1
    );

    document.getElementById('results').innerHTML =
      filtered.map(m => `
        <div class="card">
          <img src="${m.Poster}" />
          <b>${m.title}</b> (${m.year}) – ${m.imdb_rating}
        </div>
      `).join('');
  }

  document.querySelectorAll('#controls input, #controls select')
    .forEach(e => e.addEventListener('input', render));

  render();
}

init();
</script>

