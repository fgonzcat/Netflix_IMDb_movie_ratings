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


#APIKEY="1a8c9011"
#APIKEY="d7e16fa4"
APIKEY="ed6cc44c"
#APIKEY="14cf7f93"
#APIKEY="b79f4081"

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
  #movie=$(printf '%s' "$movie" | sed -e "s/’/'/g; s/–/-/g; s/—/-/g"  -e 's/%/%25/g'  -e 's/#/%23/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/"/%22/g' -e 's/ /%20/g' |  perl -CS -MUnicode::Normalize -pe '$_ = NFD($_); s/\pM//g')  # Fancy apostrophe --> normal apostrophe and no accents
  movie_safe=$(printf '%s' "$movie" | perl -CS -MUnicode::Normalize -pe '$_=NFD($_); s/\pM//g' | sed -e "s/’/'/g; s/–/-/g; s/—/-/g" -e 's/%/%25/g' -e 's/#/%23/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/‘//g' -e 's/!//g' -e 's/¡//g' -e 's/\xC2\xA0/%20/g' -e 's/"//g' -e 's/ /%20/g') # Fancy apostrophe --> normal apostrophe and no accents


  if (( $debug )); then
   echo "$movie $year $URL"
   omdb_url=$(echo "http://www.omdbapi.com/?t=$(printf '%s' "$movie_safe" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY")
   echo "curl -s \"$omdb_url\" "
  fi
  omdb_url=$(echo "http://www.omdbapi.com/?t=$(printf '%s' "$movie_safe" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY")
  json=$(curl -s "$omdb_url") 
  rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
  imdbid=$(echo "$json" | jq -r '.imdbID // empty')
  poster=$(echo "$json" | jq -r '.Poster  // empty')
  plot=$(echo "$json" | jq -r '.Plot  // empty')
  omdbError=$(echo "$json" | jq -r '.Error  // empty')

  if [ "$rating" == "N/A" ]; then
   movie_safe=$(echo "$movie" | sed "s/&/ and /g")  #  one & two --> one and two
   json=$(curl -s "http://www.omdbapi.com/?t=$(printf '%s' "$movie_safe" | sed 's/ /%20/g')&y=$year&apikey=$APIKEY")
   rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
   imdbid=$(echo "$json" | jq -r '.imdbID // empty')
   poster=$(echo "$json" | jq -r '.Poster  // empty')
   plot=$(echo "$json" | jq -r '.Plot  // empty')
  fi
  
  if [[ -n "$omdbError" ]]; then
   if [[ "$omdbError" == *"not found"* ]]; then
    omdb_url=$(echo  "http://www.omdbapi.com/?t=$(printf '%s' "$movie_safe" | sed 's/ /%20/g')&apikey=$APIKEY")
    json=$(curl -s "$omdb_url") 
    rating=$(echo "$json" | jq -r '.imdbRating // "NA"')
    imdbid=$(echo "$json" | jq -r '.imdbID // empty')
    poster=$(echo "$json" | jq -r '.Poster  // empty')
    plot=$(echo "$json" | jq -r '.Plot  // empty')
   elif [[ "$omdbError"  == *"limit"* ]]; then
     echo "⚠️  OMDb rate limit reached — skipping $movie" 
     #continue
     exit
   else
    omdb_url=$(echo  "http://www.omdbapi.com/?t=$(printf '%s' "$movie_safe" | sed 's/ /%20/g')&apikey=$APIKEY")
    echo "OMDb API error: $omdbError  :  $movie $URL $omdb_url"
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

