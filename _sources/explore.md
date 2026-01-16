# Explore Netflix Titles

Choose your criteria and explore the full catalog.


<style>
  /* Controls container */
  #controls {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    align-items: center; /* vertically center the flex items */
  }

  /* Each label is a flex container so text + input/select align nicely */
  #controls label {
    display: flex;
    flex-direction: column; /* or row if you prefer inline label+input */
    justify-content: center; /* vertical center if row */
  }

  /* Movie cards */
  .card {
    border: 1px solid #ccc;
    padding: 0.5em;
    margin: 0.5em;
    display: inline-block;
    vertical-align: top;
    width: 200px;
    text-align: center;
  }

  .card img {
    width: 100%;
    height: auto;
  }
</style>

<div id="controls">
  <label>
    Genre:
    <select id="genre"></select>
  </label>

  <label>
    Min IMDb rating:
    <input id="rating" type="number" step="0.1" value="7" style="width:4em;">
  </label>

  <label>
    Year from:
    <input id="yearFrom" type="number" value="2000" style="width:4em;">
  </label>

  <label>
    Year to:
    <input id="yearTo" type="number" value="2025" style="width:4em;">
  </label>
</div>

<div id="results" style="margin-top:1rem;"></div>



<script>
async function init() {
  const res = await fetch('./_static/data/all_movies.json');
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
  
    // Step 1: Filter movies by selected criteria
    let filtered = movies.filter(m =>
      (!g || m.genre === g) &&
      m.imdb_rating && parseFloat(m.imdb_rating) >= r &&
      parseInt(m.year) >= y0 &&
      parseInt(m.year) <= y1
    );
  
    // Step 2: Deduplicate only if "All" is selected
    if (!g) {
      const seen = new Set();
      filtered = filtered.filter(m => {
        if (seen.has(m.netflix_url)) return false;
        seen.add(m.netflix_url);
        return true;
      });
    }
  
    // Step 3: Render cards
    document.getElementById('results').innerHTML =
      filtered.map(m => `
        <div class="card">
          <a href="${m.netflix_url}" target="_blank" rel="noopener noreferrer">
            <img src="${m.Poster}" alt="${m.title}" />
          </a>
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

