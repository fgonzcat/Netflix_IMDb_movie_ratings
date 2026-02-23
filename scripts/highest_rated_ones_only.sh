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
#FINAL_JSON=$(jq -n --arg genre "$genre" \
#  --argjson movies "$FILTERED_MOVIES" \
#  '{
#    genre: $genre,
#    genre_url: null,
#    movies: $movies
#  }'
#)   # <--- list to long to give it to jq in as a single variable --argjson movies

echo -e "\nExporting best movies from each category to a single file, best.json: "
all_genres=$(echo ${REPO_ROOT}/website_jupyter_book/_static/data/*.json | xargs -n1 basename | sed 's/\.json$//')
echo "all_genres= "
echo " `echo $all_genres` "
echo "    >  ${REPO_ROOT}/website_jupyter_book/_static/data/best.json" 
#echo $FINAL_JSON | jq    >  ${REPO_ROOT}/website_jupyter_book/_static/data/best.json  # Old method, when FINAL_JSON was not long
echo "$FILTERED_MOVIES" | jq \
  --arg genre "$genre" \
  '{
    genre: $genre,
    genre_url: null,
    movies: .
  }' \
  > "${REPO_ROOT}/website_jupyter_book/_static/data/best.json"

echo -e "\nFINISHED"
echo "Updated $genre"
echo ""
echo "📝 Reminder: update the corresponding Markdown file:"
MD_FILE="$REPO_ROOT/website_jupyter_book/${genre}.md"
echo "./scripts/json_to_md.py  website_jupyter_book/_static/data/best.json   >   ${MD_FILE#$REPO_ROOT/}"    # ${VAR#PREFIX} removes PREFIX from the start of VAR, if it's there. 
