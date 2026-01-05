# Scripts
This page documents the shell scripts used to generate all movie lists on this site.
All scripts are intentionally simple and self-contained, so you can read, modify,
and run them locally.

📂 **Location**: All scripts live in the `scripts/` directory of the repository  
🔗 **Repository**: https://github.com/fgonzcat/Netfilx_IMDb_movie_ratings/



## rate_them_all_IMDb.sh
This is the **main pipeline script**.  
Given a Netflix genre URL, it:

1. Scrapes Netflix for all movie titles in that category
2. Extracts movie titles and release years
3. Queries IMDb ratings via the OMDb API
4. Produces a ranked list with IMDb and Netflix links

In short: **Netflix genre -> IMDb-ranked movie list**.

### Usage

```bash
./rate_them_all_IMDb.sh <NETFLIX_GENRE_URL>
```
### Examples
```bash
# Horror movies
./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/8711

# Cult movies
./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/7627
```
The script prints progress to stdout and writes the resulting data files
to the data/ directory.

You will see an output like this:

```bash
$ ./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/7627

CATEGORY: https://www.netflix.com/browse/genre/7627
Generating list of movies in category  https://www.netflix.com/browse/genre/7627 ...
#List of moves in genre "Cult Movies" :  https://www.netflix.com/browse/genre/7627

"Bad Education: Directors Cut"                                          2023    https://www.netflix.com/title/81713692
"Bad Trip"                                                              2021    https://www.netflix.com/title/81287254
"Battlefield Earth"                                                     2000    https://www.netflix.com/title/60000872
"Donnie Darko"                                                          2001    https://www.netflix.com/title/60022315
"Dune"                                                                  1984    https://www.netflix.com/title/464403
"Hostel: Part III"                                                      2011    https://www.netflix.com/title/70206131
"Christine"                                                             1983    https://www.netflix.com/title/70007667
"Elaan"                                                                 1971    https://www.netflix.com/title/80158482
"Labyrinth"                                                             1986    https://www.netflix.com/title/680020
"Eternal Summer"                                                        2006    https://www.netflix.com/title/70079159
"Little Women"                                                          1994    https://www.netflix.com/title/707114
"Night of the Living Dead"                                              1968    https://www.netflix.com/title/17017662
"Mean Girls"                                                            2004    https://www.netflix.com/title/60034551
"Monty Python's The Meaning of Life"                                    1983    https://www.netflix.com/title/60029676
"Pulp Fiction"                                                          1994    https://www.netflix.com/title/880640
"Pee-wee's Big Holiday"                                                 2016    https://www.netflix.com/title/80031800
"Silsila"                                                               1981    https://www.netflix.com/title/60001659
"Snatch"                                                                2000    https://www.netflix.com/title/60003388
"Stripes"                                                               1981    https://www.netflix.com/title/1008581
"The Texas Chainsaw Massacre"                                           1974    https://www.netflix.com/title/15815343
"Trailer Park Boys: The Movie"                                          2006    https://www.netflix.com/title/70069233
"This Is the End"                                                       2013    https://www.netflix.com/title/70264796
NA      "Bad Education: Directors Cut"                                          2023                                                        https://www.netflix.com/title/81713692
6.5     "Bad Trip"                                                              2021    https://www.imdb.com/title/tt9684220/               https://www.netflix.com/title/81287254
2.5     "Battlefield Earth"                                                     2000    https://www.imdb.com/title/tt0185183/               https://www.netflix.com/title/60000872
8.0     "Donnie Darko"                                                          2001    https://www.imdb.com/title/tt0246578/               https://www.netflix.com/title/60022315
```

```{note}
👉 See the formatted result in the   [**Cult Movies list**](cult).
```


### Source code

```{literalinclude} ../scripts/rate_them_all_IMDb.sh
:language: bash
:linenos:
```



---



## imdb-rating_omdbapi.sh

This script queries **IMDb ratings via the OMDb API**.

It takes a plain text list of movies (title + year) and appends:
- IMDb rating
- IMDb URL
- Netflix URL (if available)

```{warning}
⚠️ This script requires a valid **OMDb API key**, which is currently hardcoded
inside the script.
```

### Usage

```bash
./imdb-rating_omdbapi.sh <MOVIE_LIST_FILE>
```

### Example
```bash
./imdb-rating_omdbapi.sh ../data/list_Cult_Movies.txt
```

The input movie list is usually generated with:

```bash
./imdb-rating.sh --getlist https://www.netflix.com/browse/genre/7627  ../data/list_Cult_Movies.txt
```



### Source code
```bash
#######################################################################
#  Get the IMDb rating for a list of movies on Netflix                #
#######################################################################
#!/usr/bin/env bash

debug=0
if [ -z $1 ] ; then
 echo "Provide a file with movie names in each row [Berkeley 02-22-20]"
 echo ""
 echo "EXAMPLES"
 echo "Usage: $0  list.txt                                                           # A file with a list of movie titles"
 echo ""
 echo "The file list.txt must be formatted in colums like this (double quotes included):"
 echo "\"Frankenstein\"                                                          2025    https://www.netflix.com/title/81507921"
 echo "\"Clown\"                                                                 2014    https://www.netflix.com/title/80081152"
 echo "\"Veronica\"                                                              2017    https://www.netflix.com/title/80109295"
 echo "\"Viking Wolf\"                                                           2022    https://www.netflix.com/title/81338873"
 echo "\"Viral\"                                                                 2016    https://www.netflix.com/title/80076415"
 echo "\"We Have a Ghost\"                                                       2023    https://www.netflix.com/title/80230619"
 echo "\"What Lies Beneath\"                                                     2000    https://www.netflix.com/title/60001396"
 exit
elif [ "$2" == "--debug" ]; then
 debug=1
fi


APIKEY="1a8c9011"
#APIKEY="d7e16fa4"
#APIKEY="b79f4081"
#APIKEY="ed6cc44c"

list=$1                         #  Input file as first variable
# $list  must look like this:
#    #List of moves in genre "Cult Movies" :  https://www.netflix.com/browse/genre/7627
#    
#    "Bad Trip"                                          2021    https://www.netflix.com/title/81287254
#    "Bad Education: Directors Cut"                      2023    https://www.netflix.com/title/81713692
#    "Christine"                                         1983    https://www.netflix.com/title/70007667
#    "Battlefield Earth"                                 2000    https://www.netflix.com/title/60000872



while IFS= read -r movie; do
  [[ -z "$movie" || "$movie" != *title* ]] && continue
  URL=$(echo $movie | awk '{print $NF}')
  year=$(echo $movie | awk '{print $(NF-1)}')
  movie=$(echo $movie | awk '{$NF=""; $(NF-1)=""; print}')
  movie=$(echo "$movie" | sed "s/’/'/g" | perl -CS -MUnicode::Normalize -pe '$_ = NFD($_); s/\pM//g')  # Fancy apostrophe --> normal apostrophe and no accents

  if (( $debug )); then
   echo "$movie $year $URL"
   echo curl -s \""http://www.omdbapi.com/?t=$(printf '%s' "$movie" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY"\"
  fi
  json=$(curl -s "http://www.omdbapi.com/?t=$(printf '%s' "$movie" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY")
  rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
  imdbid=$(echo "$json" | jq -r '.imdbID // empty')
  omdbError=$(echo "$json" | jq -r '.Error  // empty')
  if [ "$rating" == "N/A" ]; then
   movie=$(echo "$movie" | sed "s/&/ and /g")  #  one & two --> one and two
   json=$(curl -s "http://www.omdbapi.com/?t=$(printf '%s' "$movie" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY")
   rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
   imdbid=$(echo "$json" | jq -r '.imdbID // empty')
  fi
  
  if [[ -n "$omdbError" ]]; then
   if [[ "$omdbError" == *"not found"* ]]; then
    json=$(curl -s "http://www.omdbapi.com/?t=$(printf '%s' "$movie" | sed 's/ /%20/g')&apikey=$APIKEY")
    rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
    imdbid=$(echo "$json" | jq -r '.imdbID // empty')
   else
   echo "OMDb API error: $omdbError  :  $movie $URL"
   fi
  fi


  if [[ -n "$imdbid" ]]; then
    imdb_link="https://www.imdb.com/title/$imdbid/"
  else
    imd_link="NA"
  fi


  printf "%-6s  %-70s  %-6s  %-50s  %s\n" "$rating" "$movie" "$year" "$imdb_link"  "$URL"

  # Print in CSV format
  #csv_escape() { printf '%s' "$1" | sed 's/"/""/g'; }
  #printf '%s,"%s",%s,%s,%s\n'     "$rating"     "$(csv_escape "$movie")"     "$year"     "$imdb_link"     "$URL"
done < $list
```

## Command reference

### Get a list of movies from a Netflix genre
```bash
./imdb-rating.sh --getlist <NETFLIX_GENRE_URL>
```




