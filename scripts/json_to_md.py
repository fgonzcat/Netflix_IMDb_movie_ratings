#!/usr/bin/env python
import json
import sys
from pathlib import Path

# Usage: python json_to_md.py cult.json

if len(sys.argv) != 2:
    print("Usage: python json_to_md.py <genre.json>")
    sys.exit(1)

json_file = Path(sys.argv[1])
if not json_file.exists():
    print(f"File not found: {json_file}")
    sys.exit(1)

with open(json_file) as f:
    data = json.load(f)

genre_name = data.get("genre", "Unknown Genre").capitalize()
genre_url = data.get("genre_url", "")

# Sort movies by IMDb rating (descending), missing ratings go last
def sort_key(movie):
    try:
        return float(movie.get("imdb_rating") or -1)
    except:
        return -1

movies_sorted = sorted(data.get("movies", []), key=sort_key, reverse=True)

# Header
print(f"# {genre_name} Movies on Netflix\n")
print(f'Netflix genre: <a href="{genre_url}" target="_blank">{genre_url}</a>\n')
print("## 🎬 Movie list\n")
print("| IMDb ⭐ | Poster | Year | Title | IMDb | Netflix |")
print("|:-------:|:-------:|:-------:|:------|------|---------|")

# Table rows
for movie in movies_sorted:
    imdb_rating = movie.get("imdb_rating") or "N/A"
    title = movie.get("title", "Unknown")
    imdb_id = movie.get("imdb_id")
    year    = movie.get("year")
    netflix_url = movie.get("netflix_url", "#")
    image_url   = movie.get("Poster")
    poster = f'<img src="{image_url}" class="zoom-img" width="120">'
    plot        = movie.get("Plot")
    
    #imdb_link = f'<a href="https://www.imdb.com/title/{imdb_id}/" target="_blank">https://www.imdb.com/title/{imdb_id}/</a>' if imdb_id else "N/A"
    #netflix_link = f'<a href="{netflix_url}" target="_blank">{netflix_url}</a>'
    imdb_link = f'<a href="https://www.imdb.com/title/{imdb_id}/" target="_blank">IMDb_link</a>' if imdb_id else "N/A"  # Don't display the link, just "IMDb_link"
    netflix_link = f'<a href="{netflix_url}" target="_blank">Netflix_link</a>'                                          # Don't display the link, just "Netflix_link"

    
    print(f'| {imdb_rating} | {poster} | {year} | <details> <summary><strong style="color:#1f6feb;">*{title}*</strong></summary>  <div class="movie-plot">{plot}</div> </details> | {imdb_link} | {netflix_link} |')


# Footer with workflow explanation
print(f"""

---

### 🔧 How this list was generated

Each movie list on this site is produced **automatically** using the scripts in this repository. Here’s the workflow:

1. **Select a Netflix genre**
 For example: [{genre_url}]({genre_url})

2. **Run the main script**
   ```bash
   ./rate_them_all_IMDb.sh {genre_url}
   ```

3. **What the script does**
   - Scrapes all available movie titles from the Netflix genre page
   - Retrieves IMDb ratings using the OMDb API
   - Generates a ranked list with IMDb ratings and direct links to Netflix and IMDb

4. Optional: Get all Netflix genre URLs
   ```bash
   ./imdb-rating.sh --categories
   ```
   or browse [this directory of Netflix codes](https://www.netflix-codes.com).

### Why this matters?

You don’t have to manually check IMDb for each movie — the ranking is fully reproducible and can be updated whenever you want.

```{{tip}}
💡 You can run the script for any genre URL, not just the one listed above, to generate your own custom lists.
```
""")
