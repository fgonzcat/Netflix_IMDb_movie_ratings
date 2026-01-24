# Explore Netflix Titles

Choose your criteria and explore the full catalog.

<small>
⭐ IMDb scale:  
1–3 😴 | 4–5 💣 | 6 🤔 | 7 👍 | 8+ 🌟
</small>

Interpretation
- 😴 = Very boring
- 💣 = Likely bad
- 🤔 = Might be good
- 👍 = Very likely good
- 🌟 = Excellent



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
    ⭐ Min IMDb rating:
    <input id="rating" type="number" step="0.1" value="6" style="width:4em;">
  </label>

  <label>
    Year from:
    <input id="yearFrom" type="number" value="1945" style="width:4em;">
  </label>

  <label>
    Year to:
    <input id="yearTo" type="number" value="2026" style="width:4em;">
  </label>

  <label>
    Actor:
    <select id="actor"></select>
  </label>

  <label>
    Director:
    <select id="director"></select>
  </label>

  
  <label>
    Country:
    <select id="country"></select>
  </label>

  <label>
    Language:
    <select id="language"></select>
  </label>

  <label>
    Movie/Series:
    <select id="type"></select>
  </label>

</div>

<div id="results" style="margin-top:1rem;"></div>



<script>
async function init() {
  const res = await fetch('./_static/data/all_movies.json');
  const movies = await res.json();

  const genreSel = document.getElementById('genre');
  const actorSel = document.getElementById('actor');
  const countrySel = document.getElementById('country');
  const languageSel = document.getElementById('language');
  const directorSel = document.getElementById('director');
  const typeSel     = document.getElementById('type');


  // Populate Genre options
  const genres = [...new Set(movies.map(m => m.genre))].sort();
  genreSel.innerHTML = `<option value="">All</option>` +
    genres.map(g => `<option value="${g}">${g}</option>`).join('');

  // Populate Actor options (flatten multiple actors in comma-separated list)
  const actors = [...new Set(
    movies
      .filter(m => m.Actors)           // ignore null/undefined
      .flatMap(m => m.Actors.split(',').map(a => a.trim()))
  )].sort();
  actorSel.innerHTML = `<option value="">All</option>` +
    actors.map(a => `<option value="${a}">${a}</option>`).join('');


  // Populate Country options
  const countries = [...new Set(
    movies.flatMap(m =>
      m.Country
        ? m.Country.split(',').map(c => c.trim())
        : []
    )
  )].sort();
  countrySel.innerHTML = `<option value="">All</option>` +
    countries.map(c => `<option value="${c}">${c}</option>`).join('');


  // Populate Languages
  const languages = [...new Set(
    movies.flatMap(m =>
      m.Language
        ? m.Language.split(',').map(l => l.trim())
        : []
    )
  )].sort();
  languageSel.innerHTML = `<option value="">All</option>` +
    languages.map(l => `<option value="${l}">${l}</option>`).join('');


  // Populate Directors
  const directors = [...new Set(
    movies.flatMap(m =>
      m.Director && m.Director !== "N/A"
        ? m.Director.split(',').map(d => d.trim()).filter(d => d)
        : []
    )
  )].sort();
  directorSel.innerHTML = `<option value="">All</option>` +
    directors.map(d => `<option value="${d}">${d}</option>`).join('');


  // Populate Type 
  typeSel.innerHTML = ` <option value="">All</option>
    <option value="movie">🎬 Movies</option>
    <option value="series">📺 Series</option> `;



  function render() {
    const g = genreSel.value;
    const r = parseFloat(document.getElementById('rating').value);
    const y0 = parseInt(document.getElementById('yearFrom').value);
    const y1 = parseInt(document.getElementById('yearTo').value);
    const a = actorSel.value;
    const c = countrySel.value;
    const lang = languageSel.value;
    const dir = directorSel.value;
    const type = typeSel.value;


  
    // Step 1: Filter movies by selected criteria
    let filtered = movies.filter(m =>
      (!g || m.genre === g) &&
      // IMDb rating filter
      m.imdb_rating && parseFloat(m.imdb_rating) >= r &&
      // year filter
      parseInt(m.year) >= y0 &&
      parseInt(m.year) <= y1 &&
      // actor filter (null-safe)
      (!a || (m.Actors && m.Actors.split(',').map(x => x.trim()).includes(a))) &&
      // country filter (null-safe)
      (!c || (m.Country && m.Country.includes(c))) &&
     // language filter (null-safe, token-based)
     (!lang ||   (m.Language &&  m.Language  .split(',')   .map(l => l.trim())  .includes(lang) ) )  &&
     // director filter (null-safe, token-based)
     (!dir ||    (m.Director && m.Director.split(',').map(x => x.trim()).includes(dir))) &&
     (!type || m.Type === type)
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
          <b>${m.title}</b> (${m.year})<br>
          <div class="rating">⭐ ${m.imdb_rating}</div>
        </div>
      `).join('');
  }


  document.querySelectorAll('#controls input, #controls select')
    .forEach(e => e.addEventListener('input', render));

  render();
}

init();
</script>

