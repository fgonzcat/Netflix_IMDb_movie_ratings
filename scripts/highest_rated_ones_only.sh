#!/bin/bash


# Absolute path to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root (scripts/ is one level down)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


# Old way: analyze the temporary *txt files in data/
#awk -F '\"' '/genre/{print "\n#=================#\n",$2,$3,FILENAME,"\n#=================#\n"} $1*1>=6.5 {print}' *imdb.txt

MIN_RATING=7
if [ "$1" != "" ]; then MIN_RATING=$1; fi
NEW_JSON=$(cat `ls ${REPO_ROOT}/website_jupyter_book/_static/data/*.json | grep -v 'best.json' | grep -v 'all_movies.json' ` | jq -c --arg min_rating "${MIN_RATING}"  '.movies[] | select(.imdb_rating != null and .imdb_rating != "N/A" and (.imdb_rating | tonumber) > ( $min_rating | tonumber) ) ' )

# Eliminate duplicates
NEW_JSON=$(echo "$NEW_JSON" | jq -s 'unique_by(.netflix_url)')


FILTERED_MOVIES=$(echo "$NEW_JSON" | jq -c '.')

genre="best"
FINAL_JSON=$(jq -n --arg genre "$genre" \
  --argjson movies "$FILTERED_MOVIES" \
  '{
    genre: $genre,
    genre_url: null,
    movies: $movies
  }'
)


echo -e "\nExporting best movies from each category to a single file, best.json: "
echo "all_genres= ${all_genres[@]##*/}"
echo "    >  ${REPO_ROOT}/website_jupyter_book/_static/data/best.json" 
echo $FINAL_JSON | jq    >  ${REPO_ROOT}/website_jupyter_book/_static/data/best.json
