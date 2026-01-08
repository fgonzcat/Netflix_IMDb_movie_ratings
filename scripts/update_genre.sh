#!/usr/bin/env bash
set -euo pipefail

# Usage: ./update_genre.sh cult "https://www.netflix.com/browse/genre/7627"
GENRE_NAME=$1
GENRE_URL=$2

CACHE_JSON_FILE="website_jupyter_book/_static/data/${GENRE_NAME}.json"
TMP_FILE="website_jupyter_book/_static/data/${GENRE_NAME}_tmp.json"


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
NEW_JSON=$(jq -n --argjson arr "$NEW_MOVIES_ARRAY" --arg genre "$GENRE_NAME" --arg url "$GENRE_URL" '{genre: $genre, genre_url: $url, movies: [$arr[] | .year=null | .imdb_rating=null | .imdb_id=null]}')

# Eliminate duplicates
NEW_JSON=$(echo "$NEW_JSON" | jq -r '.movies |= unique_by(.netflix_url)')






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
    year=$(wget -q -O - --user-agent="Mozilla/5.0" "$url" \
      | sed -n 's/.*"latestYear":\([0-9]\{4\}\).*/\1/p' \
      | head -1)

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


###########################################
## Step 4: OMDb search. Fill missing IMDb ratings and IDs
###########################################
echo -e "\nSTEP 4: OMDb"

#APIKEY="1a8c9011"
#APIKEY="d7e16fa4"
#APIKEY="ed6cc44c"
APIKEY="14cf7f93"
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


echo "Fetching missing IMDb ratings and IDs for new movies..."
TMP_TSV=$(mktemp)
TMP_OUT=$(mktemp)

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

jq -r '
  .movies[]
  | select(.imdb_rating == null or .imdb_id == null)
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
      # Did it work?
      if [[ -z "$imdbid" ]]; then
        echo "⚠️  OMDb lookup FAILED after retry: $title" >&2
      fi

    else
      echo "OMDb API error: $omdbError  :  $title  'http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY' "
    fi

    # Emit one result line (append-only, atomic)
    printf "%s\t%s\t%s\n" "$url" "$rating" "$imdbid"
    echo "$title -> Rating: ${rating:-NA}, ID: ${imdbid:-NA}"
  ) >> "$TMP_OUT" &

  while (( $(jobs -rp | wc -l) >= NPROC )); do sleep 0.1; done
done < "$TMP_TSV"
wait

# Reading the TMP_OUT
while IFS=$'\t' read -r url rating imdbid; do
  [[ -z "$rating" && -z "$imdbid" ]] && continue

  jq --arg u "$url" --arg r "$rating" --arg i "$imdbid" '
    .movies |= map(
      if .netflix_url == $u then
        . + (
          (if .imdb_rating == null and $r != "" then {imdb_rating: $r} else {} end) +
          (if .imdb_id     == null and $i != "" then {imdb_id:     $i} else {} end)
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
