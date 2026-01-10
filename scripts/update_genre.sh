#!/usr/bin/env bash
set -euo pipefail
: "${INTERACTIVE:=0}"   # If INTERACTIVE was already set by export INTERACTIVE=1 from another code, leave it untouched. If not, now set it to 0. 


# Usage: ./update_genre.sh cult" 
# Usage: ./update_genre.sh cult "https://www.netflix.com/browse/genre/7627"

##########################################
# Help / usage
##########################################
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -lt 1 ]]; then
    echo ""
    echo "Update or create a cached Netflix genre file with IMDb data in json format"
    echo ""
    echo "USAGE:"
    echo "  $0 <genre_name> <netflix_genre_url>"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 horror " 
    echo "  $0 horror https://www.netflix.com/browse/genre/8711"
    echo "  $0 cult   https://www.netflix.com/browse/genre/7627"
    echo ""
    echo "WHAT THIS SCRIPT DOES:"
    echo ""
    echo "  Step 1: Fetch Netflix movie list"
    echo "    - Scrapes the Netflix genre page"
    echo "    - Extracts movie titles and Netflix URLs"
    echo ""
    echo "  Step 2: Merge with existing cache (if any)"
    echo "    - Creates or updates:"
    echo "        website_jupyter_book/_static/data/<genre>.json"
    echo "    - Preserves previously fetched:"
    echo "        year, imdb_rating, imdb_id"
    echo "    - Deduplicates movies using Netflix URL"
    echo ""
    echo "  Step 3: Fill missing release years"
    echo "    - Scrapes individual Netflix movie pages"
    echo "    - Only fills movies where year == null"
    echo ""
    echo "  Step 4: Fetch IMDb ratings and IDs (OMDb)"
    echo "    - Queries OMDb using title + year"
    echo "    - Only fills movies where imdb_rating or imdb_id == null"
    echo ""
    echo "OUTPUT:"
    echo "  A fully populated JSON cache:"
    echo "    website_jupyter_book/_static/data/<genre>.json"
    echo ""
    echo "NOTES:"
    echo "  - The script is idempotent: re-running it does not redo work"
    echo "  - Safe to re-run periodically to update ratings or new titles"
    echo ""
    exit 0
fi




# Absolute path to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root (scripts/ is one level down)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"


GENRE_NAME="${1:-}"
GENRE_URL="${2:-}"
if [[ -z "$GENRE_NAME" ]]; then
    echo "ERROR: genre name required"
    echo "Usage: $0 <genre> [netflix_genre_url]"
    exit 1
fi
if [[ -z "$GENRE_URL" ]]; then
    MD_FILE="$REPO_ROOT/website_jupyter_book/${GENRE_NAME}.md"

    if [[ ! -f "$MD_FILE" ]]; then
        echo "ERROR: Netflix URL not provided and file not found:"
        echo "  $MD_FILE"
        exit 1
    fi

    GENRE_URL=$(grep -m 1 'Netflix genre:' "$MD_FILE"  | sed -n 's/.*href="\([^"]*\)".*/\1/p')

    if [[ -z "$GENRE_URL" ]]; then
        echo "ERROR: Could not extract Netflix genre URL from:"
        echo "  $MD_FILE"
        exit 1
    fi

    echo "Detected Netflix genre URL:"
    echo "  $GENRE_URL"
fi



CACHE_JSON_FILE="${REPO_ROOT}/website_jupyter_book/_static/data/${GENRE_NAME}.json"
TMP_FILE="${REPO_ROOT}/website_jupyter_book/_static/data/${GENRE_NAME}_tmp.json"



##########################################
# Step 1: fetch Netflix list and build NEW_MOVIES_ARRAY
##########################################
echo -e "\nSTEP 1: fetching titles for $GENRE_NAME"
echo "Updating genre $GENRE_NAME from $GENRE_URL..."
echo "Fetching Netflix HTML JSON for $GENRE_NAME..."
raw_json=$(wget --no-check-certificate -q -O - "$GENRE_URL" | tr '<>' '\n\n' | grep "@context")

# Convert to array of {title, netflix_url}
NEW_MOVIES=$(echo "$raw_json" | jq -c '.itemListElement[] | {title: .item.name, netflix_url: .item.url}')

# Wrap as JSON object
NEW_MOVIES_ARRAY=$(echo "$raw_json"     | jq -c '.itemListElement[] | {title: .item.name, netflix_url: .item.url}'     | jq -s '.')   # <- slurp: turns multiple JSON objects into an array
NEW_JSON=$(jq -n --argjson arr "$NEW_MOVIES_ARRAY" --arg genre "$GENRE_NAME" --arg url "$GENRE_URL" '{genre: $genre, genre_url: $url, movies: [$arr[] | .year=null | .imdb_rating=null | .imdb_id=null | .Poster=null | .Plot=null ]}')

# Eliminate duplicates
NEW_JSON=$(echo "$NEW_JSON" | jq -r '.movies |= unique_by(.netflix_url)')

# Decide whether to proceed or not (too many titles sometimes)
N=$(echo "$NEW_JSON" | jq '.movies | length')
MAX_AUTO=30
if (( INTERACTIVE )) && (( N > MAX_AUTO )); then
    printf "\033[33m⚠️  I will analyze %d titles for this genre.\033[0m\n" "$N"
    read -r -p "Proceed? [y/n] " answer
    answer=${answer:-Y}  # default Enter = yes

    [[ "$answer" =~ ^[Yy] ]] || exit 10
fi







##########################################
# Step 2: merge with existing cache (if any)
##########################################
echo -e "\nSTEP 2: checking whether $CACHE_JSON_FILE exists"
if [[ -f "$CACHE_JSON_FILE" ]]; then
    echo "Merging with existing cache..."
    jq --slurpfile new <(echo "$NEW_JSON") '
      $new[0].movies as $newarr |
      .movies as $old |
      ($newarr + $old
         | group_by(.netflix_url)
         | map(
             .[0] + (.[1:][] | {year, imdb_rating, imdb_id})
           )
      ) as $merged |
      {genre: $new[0].genre, genre_url: $new[0].genre_url, movies: $merged}
    ' "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp"
    mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
else
    echo "$NEW_JSON" > "$CACHE_JSON_FILE"
fi


##########################################
# Step 3: Fill missing years 
##########################################
# PARALLEL VERSION
echo -e "\nSTEP 3: year"
echo "Fetching missing years for new movies..."

TMP_TSV=$(mktemp)
TMP_OUT=$(mktemp)

jq -r '
  .movies[]
  | select(.year == null)
  | [.title, .netflix_url]
  | @tsv
' "$CACHE_JSON_FILE" > "$TMP_TSV"

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

while IFS=$'\t' read -r title url; do
  (
    echo "Fetching year for: $title" >&2
    year=$(wget -q -O - --user-agent="Mozilla/5.0" "$url"       | sed -n 's/.*"latestYear":\([0-9]\{4\}\).*/\1/p'       | head -1)
    if [[ -z "$year" ]]; then      echo "⚠️  Year lookup FAILED: $title" >&2;      fi

    printf "%s\t%s\n" "$url" "${year:-}"
  ) >> "$TMP_OUT" &

  while (( $(jobs -rp | wc -l) >= NPROC )); do sleep 0.1; done
done < "$TMP_TSV"

wait

while IFS=$'\t' read -r url year; do
  [[ -z "$year" ]] && continue

  jq --arg u "$url" --arg y "$year" '
    (.movies[] | select(.netflix_url == $u) | .year) = $y
  ' "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp" \
  && mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
done < "$TMP_OUT"
rm -f "$TMP_TSV" "$TMP_OUT"


## SERIAL VERSION
#echo -e "\nSTEP 3: year (SERIAL VERSION)"
#echo "Fetching missing years for new movies..."
#jq -c '.movies[] | select(.year == null)' "$CACHE_JSON_FILE" | while read -r movie; do
#    title=$(echo "$movie" | jq -r '.title')
#    url=$(echo "$movie" | jq -r '.netflix_url')
#
#    year=$(wget -q -O - --user-agent="Mozilla/5.0" "$url" \
#        | sed -n 's/.*"latestYear":\([0-9]\{4\}\).*/\1/p' \
#        | head -1)
#
#    jq --arg u "$url" --arg y "$year" \
#       '(.movies[] | select(.netflix_url==$u) | .year) |= ($y // null)' \
#       "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp" \
#       && mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
#
#    echo "$title $url $year"
#done

wait
echo "... years fetched in $CACHE_JSON_FILE"


##########################################
# Step 4: OMDb search. Fill missing IMDb ratings and IDs
##########################################
echo -e "\nSTEP 4: OMDb"

APIKEY="1a8c9011"
#APIKEY="d7e16fa4"
#APIKEY="ed6cc44c"
#APIKEY="14cf7f93"
#APIKEY="b79f4081"

#echo "Fetching missing IMDb ratings and IDs for new movies..."
#
#jq -c '.movies[] | select(.imdb_rating == null or .imdb_id == null)' "$CACHE_JSON_FILE" | while read -r movie; do
#    title=$(echo "$movie" | jq -r '.title')
#    year=$(echo "$movie" | jq -r '.year')
#    url=$(echo "$movie" | jq -r '.netflix_url')
#    safe_title=$(printf '%s' "$title" | perl -CS -MUnicode::Normalize -pe '$_=NFD($_); s/\pM//g' | sed -e "s/’/'/g; s/–/-/g; s/—/-/g" -e 's/%/%25/g' -e 's/#/%23/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/‘//g' -e 's/!//g' -e 's/¡//g' -e 's/\xC2\xA0/%20/g' -e 's/ /%20/g') # No fancy apostrophes, no accents, no weird unicode, etc
#
#    # Fetch OMDb info
#    json=$(curl -s "http://www.omdbapi.com/?t=$safe_title&y=$year&apikey=$APIKEY")
#    rating=$(echo "$json" | jq -r '.imdbRating // empty')
#    imdbid=$(echo "$json" | jq -r '.imdbID // empty')
#    omdbError=$(echo "$json" | jq -r '.Error  // empty')
#
#    if [[ -n "$omdbError" ]]; then
#     if [[ "$omdbError" == *"not found"* ]]; then
#      json=$(curl -s "http://www.omdbapi.com/?t=$(printf '%s' "$safe_title" | sed 's/ /%20/g')&apikey=$APIKEY")  # Ignore the year
#      rating=$(echo "$json" | jq -r '.imdbRating // empty')
#      imdbid=$(echo "$json" | jq -r '.imdbID // empty')
#     else
#     echo "OMDb API error: $omdbError  :  $movie $URL"
#     fi
#    fi
#
#
#
#    ## Update JSON in-place
#    #jq --arg u "$title" --arg r "$rating" --arg i "$imdbid" \
#    #   '(.movies[] | select(.title==$u) | .imdb_rating) |= ($r // null) |
#    #    (.movies[] | select(.title==$u) | .imdb_id) |= ($i // null)' \
#    #   "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp" && mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
#
#    jq --arg u "$url" --arg r "$rating" --arg i "$imdbid" '
#      .movies |= map(
#        if .netflix_url == $u then
#          . + (
#            (if .imdb_rating == null and $r != "" then {imdb_rating: $r} else {} end) +
#            (if .imdb_id     == null and $i != "" then {imdb_id:     $i} else {} end)
#          )
#        else .
#        end
#      )
#    ' "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp" && mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
#
#
#    echo "$title -> Rating: ${rating:-NA}, ID: ${imdbid:-NA}"
#done
#
#echo "IMDb ratings and IDs filled in $CACHE_JSON_FILE"


echo "Fetching missing IMDb ratings, IDs, Poster, and Plot for new movies..."
TMP_TSV=$(mktemp)
TMP_OUT=$(mktemp)

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

jq -r '
  .movies[]
  | select(.imdb_rating == null or .imdb_id == null or .Poster == null or .Plot == null)
  | [.title, .year, .netflix_url]
  | @tsv
' "$CACHE_JSON_FILE" > "$TMP_TSV"

# Reading the TMP_TSV: a json file only with missing IMDb rating
while IFS=$'\t' read -r title year url; do
  (
    echo "Processing OMDb: $title ($year)" >&2

    safe_title=$(printf '%s' "$title" \
      | perl -CS -MUnicode::Normalize -pe '$_=NFD($_); s/\pM//g' \
      | sed -e "s/’/'/g; s/–/-/g; s/—/-/g" \
            -e 's/%/%25/g; s/#/%23/g; s/&/%26/g; s/?/%3F/g' \
            -e 's/‘//g; s/!//g; s/¡//g' \
            -e 's/\xC2\xA0/%20/g; s/ /%20/g')

    omdb_url=$(echo "http://www.omdbapi.com/?t=$safe_title&y=$year&apikey=$APIKEY")
    json=$(curl -s "$omdb_url") 
    rating=$(echo "$json" | jq -r '.imdbRating // empty')
    imdbid=$(echo "$json" | jq -r '.imdbID // empty')
    poster=$(echo "$json" | jq -r '.Poster  // empty')
    plot=$(echo "$json" | jq -r '.Plot  // empty')
    omdbError=$(echo "$json" | jq -r '.Error // empty')

    if [[ -n "$omdbError"  ]]; then
      if [[ "$omdbError"  == *limit* ]]; then
       echo "⚠️  OMDb rate limit reached — skipping $title" >&2
       #continue
       exit
      fi
      # Retry without a year
      omdb_url=$(echo "http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY")
      json=$(curl -s "$omdb_url") 
      rating=$(echo "$json" | jq -r '.imdbRating // empty')
      imdbid=$(echo "$json" | jq -r '.imdbID // empty')
      poster=$(echo "$json" | jq -r '.Poster  // empty')
      plot=$(echo "$json" | jq -r '.Plot  // empty')
      # Did it work?
      if [[ -z "$imdbid" ]]; then
        echo "⚠️  OMDb lookup FAILED after retry: $title   $omdbError  :  $title  'http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY' " >&2
      fi

    else
      echo "⚠️  OMDb API error: $omdbError  :  $title  'http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY' "
    fi

    plot=${plot//$'\t'/ }      # replace tabs
    plot=${plot//$'\n'/ }      # replace newlines

    # Emit one result line (append-only, atomic)
    printf "%s\t%s\t%s\t%s\t%s\n" "$url" "$rating" "$imdbid" "$poster" "$plot"
    #printf "%s\t%s\t%s\n" "$url" "$rating" "$imdbid"
    echo "$title -> Rating: ${rating:-NA}, ID: ${imdbid:-NA}"
  ) >> "$TMP_OUT" &

  while (( $(jobs -rp | wc -l) >= NPROC )); do sleep 0.1; done
done < "$TMP_TSV"
wait

# Reading the TMP_OUT
while IFS=$'\t' read -r url rating imdbid poster plot; do
  [[ -z "$rating" && -z "$imdbid" ]] && continue

  jq --arg u "$url" --arg r "$rating" --arg i "$imdbid" --arg p "$poster" --arg l "$plot" '
    .movies |= map(
      if .netflix_url == $u then
        . + (
          (if .imdb_rating == null and $r != "" then {imdb_rating: $r} else {} end) +
          (if .imdb_id     == null and $i != "" then {imdb_id:     $i} else {} end) +
          (if .Poster      == null and $p != "" then {Poster:      $p} else {} end) +
          (if .Plot        == null and $l != "" then {Plot:        $l} else {} end)
        )
      else .
      end
    )
  ' "$CACHE_JSON_FILE" > "${CACHE_JSON_FILE}.tmp" \
  && mv "${CACHE_JSON_FILE}.tmp" "$CACHE_JSON_FILE"
done < "$TMP_OUT"

rm -f "$TMP_TSV" "$TMP_OUT"
echo "IMDb ratings and IDs filled in $CACHE_JSON_FILE"



wait
echo -e "\nFINISHED"
echo "Updated cache: $CACHE_JSON_FILE"
