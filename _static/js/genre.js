//  What this function does (exactly)
// Loads the correct JSON file:
//     _static/data/scifi.json
//     _static/data/noir.json
// Assumes movies are already sorted (by IMDb)
// Renders them as HTML
// Handles errors gracefully
// It does nothing else.
// No sorting. No shuffling. No data mutation.


function loadGenre(genre) {
  fetch(`_static/data/${genre}.json`)
    .then(response => {
      if (!response.ok) {
        throw new Error(`Cannot load genre: ${genre}`);
      }
      return response.json();
    })
    .then(data => {
      document.getElementById("movies").innerHTML =
        data.movies
          .map(m => `
            <p>
              <strong>${m.title}</strong> (${m.year})
              — ⭐ ${m.imdb_rating}
              — <a href="${m.netflix_url}" target="_blank">Netflix</a>
            </p>
          `)
          .join("");
    })
    .catch(err => {
      document.getElementById("movies").innerHTML =
        `<p style="color:red">Error loading genre data.</p>`;
      console.error(err);
    });
}

