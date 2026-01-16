#!/usr/bin/env bash
#
# merge_all_movies_to_json.sh
#
# This script generates a single aggregated JSON file, `all_movies.json`,
# from the individual genre files in:
#
#   website_jupyter_book/_static/data/
#
# Each genre file (e.g. `horror.json`, `cult.json`, `anime.json`) has the form:
#
#   {
#     "genre": "...",
#     "genre_url": "https://www.netflix.com/browse/genre/XXXX",
#     "movies": [ { ... }, { ... }, ... ]
#   }
#
# For each input file, this script:
#
#   1. Reads `genre_url` using `jq`.
#   2. Fetches the corresponding Netflix genre page.
#   3. Extracts the human-readable genre name from the embedded JSON-LD
#      (`"@type":"ItemList","name": ...`).
#   4. Attaches that name as a new `"genre"` field to *every* movie
#      in that file.
#   5. Emits all movies from all genres as a single flat list.
#
# The final output is written to:
#
#   website_jupyter_book/_static/data/all_movies.json
#
# and has the form:
#
#   [
#     { ...movie fields..., "genre": "Horror" },
#     { ...movie fields..., "genre": "Cult Movies" },
#     ...
#   ]
#
# This file is meant to be called directly by `explore.md` in the Jupyter Book, which expects
# a single JSON array with a `"genre"` field on each movie in order to drive
# the filtering UI.
#
# Notes:
#   - `all_movies.json` itself is never read as input; it is overwritten.
#   - `best.json` is handled separately elsewhere and is excluded here.
#   - A small normalization hack maps Netflix’s “Essential Horror Flicks”
#     back to simply “Horror” to keep genre labels stable.
#
# Requirements:
#   - bash
#   - jq
#   - wget
#


# Absolute path to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root (scripts/ is one level down)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


all_genres=( ${REPO_ROOT}/website_jupyter_book/_static/data/*.json)
echo -e "\nExporting all movies from all categories to a single file, all_movies.json: "
echo "all_genres= ${all_genres[@]##*/}"
echo "    >  ${REPO_ROOT}/website_jupyter_book/_static/data/all_movies.json" 

for f in "${all_genres[@]}"
do
  case "$(basename "$f")" in    all_movies.json|best.json) continue ;;   esac

  #genre_url=$(jq -r '.genre_url' "$f")
  #genre_name=$(  wget -q -O - "$genre_url" |     tr '{' '\n' |     grep '"@type":"ItemList","name":' |    sed -E 's/.*"name":"([^"]+)".*/\1/'   )

  # For a given JSON file $f
  base=$(basename "$f" .json)       # e.g., "cult"
  md_file="$REPO_ROOT/website_jupyter_book/$base.md"
  genre_url=$(jq -r '.genre_url' "$f")
  genre_name=$(head -n1 "$md_file" | sed -E 's/^# *//')



  #if [[ "$genre_name" == *"Essential Horror"* ]]; then  genre_name="Horror"; fi
  jq --arg genre "$genre_name" '.movies[] + {genre: $genre}' "$f" 
done  | jq -s .   >  ${REPO_ROOT}/website_jupyter_book/_static/data/all_movies.json 



