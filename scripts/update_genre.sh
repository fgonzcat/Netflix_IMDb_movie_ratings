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


GENRE_NAME=""
GENRE_URL=""
APIKEY=""
for arg in "$@"; do
 case "$arg" in
  --apikey=*)
      APIKEY="${arg#--apikey=}"
      ;;
  *)
      if [[ -z "$GENRE_NAME" ]]; then
          GENRE_NAME="$arg"
      elif [[ -z "$GENRE_URL" ]]; then
          GENRE_URL="$arg"
      fi
      ;;
 esac
done


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
# Only fields we know from Netflix: title + netflix_url
# Year, imdb_rating, imdb_id are set to null as placeholders
# Poster and Plot are not set at all here — they stay out
NEW_MOVIES_ARRAY=$(echo "$raw_json"     | jq -c '.itemListElement[] | {title: .item.name, netflix_url: .item.url}'     | jq -s '.')   # <- slurp: turns multiple JSON objects into an array
#NEW_JSON=$(jq -n --argjson arr "$NEW_MOVIES_ARRAY" --arg genre "$GENRE_NAME" --arg url "$GENRE_URL" '{genre: $genre, genre_url: $url, movies: [$arr[] | .year=null | .imdb_rating=null | .imdb_id=null | .Poster=null | .Plot=null ]}')
NEW_JSON=$(jq -n --argjson arr "$NEW_MOVIES_ARRAY" --arg genre "$GENRE_NAME" --arg url "$GENRE_URL"  '{genre: $genre, genre_url: $url, movies: [$arr[] | .year=null | .imdb_rating=null | .imdb_id=null]}')


# Eliminate duplicates
NEW_JSON=$(echo "$NEW_JSON" | jq -r '.movies |= unique_by(.netflix_url)')

# Decide whether to proceed or not (too many titles sometimes)
N=$(echo "$NEW_JSON" | jq '.movies | length')
MAX_AUTO=30
printf "\033[33m⚠️  I will analyze %d titles for this genre.\033[0m\n" "$N"
if (( INTERACTIVE )) && (( N > MAX_AUTO )); then
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
    
      # merge by netflix_url
      ($newarr + $old
         | group_by(.netflix_url)
         | map(
             # base is first old movie if exists, otherwise new movie
             (map(select(.year != null or .imdb_rating != null or .imdb_id != null))[0] // .[0])
             as $base |
    
             # merge all other entries, keeping any fields not already in base
             reduce .[] as $item ($base;
               . + ($item | del(.title, .netflix_url)) # merge all fields except title/url
             )
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

if [ "$APIKEY" == "" ]; then
 APIKEY="1a8c9011"
 #APIKEY="d7e16fa4"
 #APIKEY="ed6cc44c"
 #APIKEY="14cf7f93"
 #APIKEY="b79f4081"
fi

echo "Fetching missing IMDb ratings, IDs, Poster, and Plot for new movies..."
echo "APIKEY= $APIKEY"
TMP_TSV=$(mktemp)
TMP_OUT=$(mktemp)

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

jq -r '
  .movies[]
  | select(.imdb_rating == null or .imdb_id == null or .Poster == null or .Plot == null or .Actors == null)
  | [.title, .year, .netflix_url]
  | @tsv
' "$CACHE_JSON_FILE" > "$TMP_TSV"

tmp_json=$(jq -r '.movies[]   | select((.imdb_rating == null or .imdb_id == null or .Poster == null or .Plot == null or  .Actors == null)  and (.SkipTitle // false | not))' "$CACHE_JSON_FILE"  )
N=$(echo $tmp_json | jq -r ' .title ' | wc -l)
printf "\033[33m--> Performing %d calls to OMDb...\033[0m\n" "$N"

# Reading the TMP_TSV: a json file only with missing IMDb rating
while IFS=$'\t' read -r title year url; do
  (
    # HANDLE EXCEPTIONS MANUALLY
    if [[ "$title" == *Warmest*Color* ]]; then 
     title=$(echo $title | sed -e 's/Color/Colour/g')
    elif [[ "$title" == *Monster* && $year == "2024" ]]; then 
      echo "Skipping OMDb for manual exception: $title ($year)" >&2
      exit 0   # terminate this worker cleanly
    fi 

    # Skip based on previous failure (SkipTitle)
    if [[ -f "$TMP_OUT" ]]; then
      skip=$(jq -r --arg u "$url" '.movies[] | select(.netflix_url==$u) | .SkipTitle // false' "$CACHE_JSON_FILE")
      if [[ "$skip" == "true" ]]; then
        echo "⏭️  Skipping $title because it previously failed" >&2
        exit 0
      fi
    fi

    echo "Processing OMDb: $title ($year)"   >&2
    safe_title=$(printf '%s' "$title" \
      | perl -CS -MUnicode::Normalize -pe '$_=NFD($_); s/\pM//g' \
      | sed -e "s/’/'/g; s/–/-/g; s/—/+/g; s/-/+/g;" \
            -e 's/%/%25/g; s/#/%23/g; s/&/%26/g; s/?/%3F/g' \
            -e 's/‘//g; s/!//g; s/¡//g' \
            -e 's/\xC2\xA0/ /g; s/[[:space:]]\+/+/g; s/ /+/g')


    omdb_url=$(echo "http://www.omdbapi.com/?t=$safe_title&y=$year&apikey=$APIKEY")
    json=$(curl -s "$omdb_url") 
    # Fields typically available in OMDb ($json):
    #  {
    #    "Title": "Atlas",
    #    "Year": "2024",
    #    "Rated": "PG-13",
    #    "Released": "24 May 2024",
    #    "Runtime": "118 min",
    #    "Genre": "Action, Adventure, Drama",
    #    "Director": "Brad Peyton",
    #    "Writer": "Leo Sardarian, Aron Eli Coleite",
    #    "Actors": "Jennifer Lopez, Simu Liu, Sterling K. Brown",
    #    "Plot": "In a bleak-sounding future, an A.I. soldier has determined that the only way to end war is to end humanity.",
    #    "Language": "English",
    #    "Country": "United States",
    #    "Awards": "2 wins & 4 nominations total",
    #    "Poster": "https://m.media-amazon.com/images/M/MV5BNDUwNTFkNzYtMGM5NS00NTc4LWEwMDUtMmE5MzgyMjcwOWM4XkEyXkFqcGc@._V1_SX300.jpg",
    #    "Ratings": [
    #      {
    #        "Source": "Internet Movie Database",
    #        "Value": "5.6/10"
    #      },
    #      {
    #        "Source": "Rotten Tomatoes",
    #        "Value": "18%"
    #      },
    #      {
    #        "Source": "Metacritic",
    #        "Value": "37/100"
    #      }
    #    ],
    #    "Metascore": "37",
    #    "imdbRating": "5.6",
    #    "imdbVotes": "58,016",
    #    "imdbID": "tt14856980",
    #    "Type": "movie",
    #    "DVD": "N/A",
    #    "BoxOffice": "N/A",
    #    "Production": "N/A",
    #    "Website": "N/A",
    #    "Response": "True"
    #  }


    rating=$(echo "$json" | jq -r '.imdbRating // empty')
    imdbid=$(echo "$json" | jq -r '.imdbID // empty')
    Poster=$(echo "$json" | jq -r '.Poster  // empty')
    Plot=$(echo "$json" | jq -r '.Plot  // empty')
    Type=$(echo "$json" | jq -r '.Type  // empty')
    Title=$(echo "$json" | jq -r '.Title // empty')
    RunTime=$(echo "$json" | jq -r '.Runtime // empty')
    Genre=$(echo "$json" | jq -r '.Genre // empty')
    Director=$(echo "$json" | jq -r '.Director // empty')
    Writer=$(echo "$json" | jq -r '.Writer // empty')
    Actors=$(echo "$json" | jq -r '.Actors // empty')
    Language=$(echo "$json" | jq -r '.Language // empty')
    Country=$(echo "$json" | jq -r '.Country // empty')
    omdbError=$(echo "$json" | jq -r '.Error // empty')
    if [[ "$Country" == *USA* ]]; then  Country=$(echo "$Country" | sed 's/USA/United States/g'); fi

    # First, let's check whether the title from Netflix ($title) is the same I found in OMDb after the search ($Title)
    if [[ -n "$Title" ]]; then
     norm_title=$(echo      "$title"  | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C sed -E 's/[^a-z0-9]+/ /g; s/^ +| +$//g') 
     norm_omdb_title=$(echo "$Title"  | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C sed -E 's/[^a-z0-9]+/ /g; s/^ +| +$//g')
    fi

    if [[ -n "$omdbError" ]] || [[ -n "$Title" && "$norm_title" != "$norm_omdb_title" ]]; then
      if [[ "$omdbError"  == *limit* ]]; then
       echo "⚠️  OMDb rate limit reached — skipping $title" >&2
       #continue
       touch "$TMP_OUT.limit"
       exit
      fi

      ## Retry without a year
      #omdb_url=$(echo "http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY")

      ## Fetch Info from Netflix JSON
      #netflix_json=$(wget -q -O - --user-agent="Mozilla/5.0" "$url"    | tr '<>' '\n\n'   | grep actors | grep -m 1 context   | jq '.')
      #netflix_title=$(echo "$netflix_json" | jq -r '.name')
      #netflix_type=$(echo "$netflix_json" | jq -r '.["@type"]')
      #netflix_year=$(echo "$netflix_json" | jq -r '.dateCreated' | cut -d- -f1)


      #===================================#
      #           TRY AGAIN               #
      #===================================#
      # Retry using the first search result by OMDb rather than with no year
      echo " ❌ CAN'T FIND $title. Originally:   safe_title= $safe_title"    >&2
      safe_title=$(echo "$safe_title" | sed -E 's/[Tt]he\+Movie:?//g; s/\+\+/+/g; s/^\+//; s/\+$//')  # Remove literal “the+Movie”, collapse “++” into “+”, and trim leading/trailing “+”
      omdb_url="http://www.omdbapi.com/?s=$safe_title&apikey=$APIKEY"                                        # No year, and Switch from exact title match (?t=) to search mode (?s=)
      # Look at the Netflix exact type for the titlee
      netflix_json=$(wget -q -O - "$url" | tr '<>' '\n\n' | grep actors | grep -m 1 context | jq '.' 2>/dev/null || echo "")
      netflix_type=$(echo "$netflix_json" | jq -r '.["@type"]')
      if [[ "$netflix_type" == *Serie* ]]; then netflix_type="series";
      elif [[ "$netflix_type" == "Movie" ]]; then netflix_type="movie"; fi


      #search0=$(curl -s "$omdb_url" | jq -r '.Search[0]')      # Just naiively pick the first result of the list (0) 

      # Let's look more carefylly inside the list of the $omdb_url search:
      search=$(curl -s "$omdb_url" )   # All search results in a json list: {"Search":[{"Title":"...},...,{"Title":...} ] }
      if ! echo "$search" | jq -e '.Response=="True"' >/dev/null; then
        echo "OMDb search failed" >&2
        exit 1
      fi
      search_array=$(echo "$search" | jq -c '.Search // empty')
      search0=$(
        echo "$search_array" |
        jq -c --arg title "$safe_title" --arg type "$netflix_type" '
          # Helper: lowercase strings for case-insensitive comparison
          def norm: ascii_downcase;
      
          # Save the input array as $S for repeated use
          . as $S
      
          | (  # 1️⃣  Exact match: title AND type
              $S | map(select(type=="object"  and (.Title | norm) == ($title | norm) and .Type == $type)) | .[0]
            )
            // # 2️⃣ Fallback: Title match only
            (  
              $S | map(select(type=="object" and (.Title | norm) == ($title | norm))) | .[0]
            )
            // # 3️⃣ Fallback: Type match only
            (
              $S | map(select(type=="object" and .Type == $type))  | .[0]
            )
            //  # 4️⃣ Final fallback: just pick the first element of the array
            $S[0]
        '
      )

      omdb_search0_title=$(echo $search0 | jq -r '.Title // empty')                   # Extract the Title of the first search result (or empty if none)
      imdb_id_from_search0=$(echo $search0 | jq -r '.imdbID // empty')      
      if [ -n "$omdb_search0_title" ]; then                                          # If OMDb returned at least one result...
          safe_title=$(printf '%s' "$omdb_search0_title" \
            | perl -CS -MUnicode::Normalize -pe '$_=NFD($_); s/\pM//g' \
            | sed -E \
                  -e "s/’/'/g; s/–/-/g; s/—/+/g; s/-/+/g" \
                  -e 's/[[:space:]]\+/+/g; s/^\+//; s/\+$//' \
                  -e 's/[(]/%28/g' -e 's/[)]/%29/g')
      fi
      safe_title=$(echo "$safe_title"   | sed -e 's/ /+/g' -e 's/://g' -e 's/&/%26/g' -e 's/(/%28/g' -e 's/)/%29/g')  # Final URL-escaping / cleanup pass


      echo "   ---> 🔍 I'm gonna try to search (?s=) rather than to match (?t=) title for '$title':  $omdb_url" >&2
      echo "   ---> 🔍 For '$title', the OMDb search returned title= '$omdb_search0_title'"     >&2


      # Back to  exact title match (?t=), but with $safe_title from the $omdb_search0_title.
      #omdb_url=$(echo "http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY")
      omdb_url=$(echo "http://www.omdbapi.com/?i=$imdb_id_from_search0&apikey=$APIKEY")
      echo "   ---> New safe title: $safe_title searched with:  $omdb_url  -> https://www.imdb.com/title/$imdb_id_from_search0 -> $url"        >&2
      json=$(curl -s "$omdb_url") 
      rating=$(echo "$json" | jq -r '.imdbRating // empty')
      imdbid=$(echo "$json" | jq -r '.imdbID // empty')
      Poster=$(echo "$json" | jq -r '.Poster  // empty')
      Plot=$(echo "$json" | jq -r '.Plot  // empty')
      Type=$(echo "$json" | jq -r '.Type  // empty')
      Title=$(echo "$json" | jq -r '.Title // empty')
      RunTime=$(echo "$json" | jq -r '.Runtime // empty')
      Genre=$(echo "$json" | jq -r '.Genre // empty')
      Director=$(echo "$json" | jq -r '.Director // empty')
      Writer=$(echo "$json" | jq -r '.Writer // empty')
      Actors=$(echo "$json" | jq -r '.Actors // empty')
      Language=$(echo "$json" | jq -r '.Language // empty')
      Country=$(echo "$json" | jq -r '.Country // empty')
      if [[ "$Country" == *USA* ]]; then  Country=$(echo "$Country" | sed 's/USA/United States/g'); fi
      # Did it work?
      if [[ -z "$imdbid" ]]; then
        echo "⚠️  OMDb lookup FAILED after retry: $title   $omdbError  :  $title  'http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY' " >&2
        # Safely mark SkipTitle=true
        tmpfile=$(mktemp)
        if jq --arg u "$url" '.movies |= map(if .netflix_url==$u then . + {"SkipTitle": true} else . end)' \
            "$CACHE_JSON_FILE" > "$tmpfile"; then
            mv "$tmpfile" "$CACHE_JSON_FILE"
        else
            echo "❌  Failed to mark SkipTitle for $title — original JSON preserved" >&2
            rm -f "$tmpfile"
        fi
      fi

    else
      echo "⚠️  OMDb API error: $omdbError  :  $title  'http://www.omdbapi.com/?t=$safe_title&apikey=$APIKEY' "
    fi

    Plot=${Plot//$'\t'/ }      # replace tabs
    Plot=${Plot//$'\n'/ }      # replace newlines

    # Emit one result line (append-only, atomic)
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$url" "$rating" "$imdbid" "$Poster" "$Plot" "$Type" "$Title" "$RunTime" "$Genre" "$Director" "$Writer" "$Actors" "$Language" "$Country"
    #printf "%s\t%s\t%s\n" "$url" "$rating" "$imdbid"
    echo "$title -> Rating: ${rating:-NA}, ID: ${imdbid:-NA}"
  ) >> "$TMP_OUT" &

  while (( $(jobs -rp | wc -l) >= NPROC )); do sleep 0.1; done
done < "$TMP_TSV"
wait


# CHECK WHETHER YOU EXCEEDED THE MAX NUMBER OF DAILY REQUESTS
if [[ -f "$TMP_OUT.limit" ]]; then
  echo "❌ OMDb rate limit was hit. Aborting without modifying cache." >&2
  echo "❌ $CACHE_JSON_FILE was not updated.                         " >&2
  rm -f "$TMP_TSV" "$TMP_OUT" "$TMP_OUT.limit"
  exit 1
fi


# Reading the TMP_OUT
while IFS=$'\t' read -r url rating imdbid Poster Plot Type Title RunTime Genre Director Writer Actors Language Country; do
  [[ -z "$rating" && -z "$imdbid" ]] && continue

  jq --arg u "$url" --arg r "$rating" --arg i "$imdbid" --arg poster "$Poster" --arg plot "$Plot" --arg tp "$Type" --arg runtime "$RunTime" --arg genre "$Genre" --arg director "$Director" --arg writer "$Writer" --arg actors "$Actors"  --arg lang "$Language" --arg country "$Country" '
    .movies |= map(
      if .netflix_url == $u then
        . + (
          (if .imdb_rating == null and $r != "" then {imdb_rating: $r} else {} end) +
          (if .imdb_id     == null and $i != "" then {imdb_id:     $i} else {} end) +
          (if .Poster      == null and $poster   != "" then {Poster:      $poster   } else {} end) +
          (if .Plot        == null and $plot     != "" then {Plot:        $plot     } else {} end) +
          (if .Type        == null and $tp       != "" then {Type:        $tp       } else {} end) +
          (if .RunTime     == null and $runtime  != "" then {RunTime:     $runtime  } else {} end) +
          (if .Genre       == null and $genre    != "" then {Genre:       $genre    } else {} end) +
          (if .Director    == null and $director != "" then {Director:    $director } else {} end) +
          (if .Writer      == null and $writer   != "" then {Writer:      $writer   } else {} end) +
          (if .Actors      == null and $actors   != "" then {Actors:      $actors   } else {} end) +
          (if .Language    == null and $lang     != "" then {Language:    $lang     } else {} end) +
          (if .Country     == null and $country  != "" then {Country:     $country  } else {} end)
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
echo ""
echo "📝 Reminder: update the corresponding Markdown file:"
MD_FILE="$REPO_ROOT/website_jupyter_book/${GENRE_NAME}.md"
echo "./scripts/json_to_md.py  "${CACHE_JSON_FILE#$REPO_ROOT/}"   >   ${MD_FILE#$REPO_ROOT/}"    # ${VAR#PREFIX} removes PREFIX from the start of VAR, if it's there. 
