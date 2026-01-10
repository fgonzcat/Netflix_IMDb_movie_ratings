#######################################################################
#  Get the IMDb rating for a list of movies on Netflix                #
#######################################################################
#!/usr/bin/env bash

if [ -z $1 ] ; then
 echo "Provide a file with movie names in each row [Berkeley 02-22-20]"
 echo ""
 echo "EXAMPLES"
 echo "Usage: $0  list.txt                                                           # A file with a list of movie titles"
 echo "Usage: $0  --getlist  https://www.netflix.com/browse/genre/8711?bc=34399      # get list of horror movies"
 echo "Usage: $0  --categories                                                       # get URLs of Netflix categories"
 echo "Usage: $0  --not-found   list_ratings.txt                                     # An output file of $0"
 exit
fi

list=$1
debug=0

listURL=""
while [ $# -gt 0 ]; do
 case $1 in
  -g|--getlist)
   listURL=$2
   shift
   ;;
  --movie)
   echo $2 > tmp.tmp
   list=tmp.tmp
   shift
   ;;
  -d|--debug)
   debug=1
   shift
   ;;
  --not-found)
   awk '/Not-found/{$1="";$NF=""; print }'  $2
   shift
   exit
   ;;
  --categories)
echo "Action & Adventure                                 https://www.netflix.com/browse/genre/1365"
echo "Action Comedies                                    https://www.netflix.com/browse/genre/43040"
echo "Action Thrillers                                   https://www.netflix.com/browse/genre/43048"
echo "Adventures                                         https://www.netflix.com/browse/genre/7442"
echo "Asian Action Movies                                https://www.netflix.com/browse/genre/77232"
echo "Classic Action & Adventure                         https://www.netflix.com/browse/genre/46576"
echo "Comic Book & Superhero Movies                      https://www.netflix.com/browse/genre/10118"
echo "Crime Action & Adventure                           https://www.netflix.com/browse/genre/9584"
echo "Foreign Action & Adventure                         https://www.netflix.com/browse/genre/11828"
echo "Martial Arts Movies                                https://www.netflix.com/browse/genre/8985"
echo "Military Action & Adventure                        https://www.netflix.com/browse/genre/2125"
echo "Spy Action & Adventure                             https://www.netflix.com/browse/genre/10702"
echo "Westerns                                           https://www.netflix.com/browse/genre/7700"
echo ""
echo "Animation                                          https://www.netflix.com/browse/genre/4698"
echo "Adult Animation                                    https://www.netflix.com/browse/genre/11881"
echo ""
echo "Anime                                              https://www.netflix.com/browse/genre/7424"
echo "Anime Action                                       https://www.netflix.com/browse/genre/2653"
echo "Anime Comedies                                     https://www.netflix.com/browse/genre/9302"
echo "Anime Dramas                                       https://www.netflix.com/browse/genre/452"
echo "Anime Fantasy                                      https://www.netflix.com/browse/genre/11146"
echo "Anime Features                                     https://www.netflix.com/browse/genre/3063"
echo "Anime Horror                                       https://www.netflix.com/browse/genre/10695"
echo "Anime Sci-Fi                                       https://www.netflix.com/browse/genre/2729"
echo "Anime Series                                       https://www.netflix.com/browse/genre/6721"
echo ""
echo "Children & Family Films                            https://www.netflix.com/browse/genre/783"
echo "Animal Tales                                       https://www.netflix.com/browse/genre/5507"
echo "Disney                                             https://www.netflix.com/browse/genre/67673"
echo "Education for Kids                                 https://www.netflix.com/browse/genre/10659"
echo "Family Features                                    https://www.netflix.com/browse/genre/51056"
echo "Kids Music                                         https://www.netflix.com/browse/genre/52843"
echo "Kids TV                                            https://www.netflix.com/browse/genre/27346"
echo "Movies Based on Kids’ Books                        https://www.netflix.com/browse/genre/10056"
echo "Movies for Ages 0-2                                https://www.netflix.com/browse/genre/6796"
echo "Movies for Ages 2-4                                https://www.netflix.com/browse/genre/6218"
echo "Movies for Ages 5-7                                https://www.netflix.com/browse/genre/5455"
echo "Movies for Ages 8-10                               https://www.netflix.com/browse/genre/561"
echo "Movies for Ages 11-12                              https://www.netflix.com/browse/genre/6962"
echo "TV Cartoons                                        https://www.netflix.com/browse/genre/11177"
echo ""
echo "Classics                                           https://www.netflix.com/browse/genre/31574"
echo "Classic Comedies                                   https://www.netflix.com/browse/genre/31694"
echo "Classic Dramas                                     https://www.netflix.com/browse/genre/29809"
echo "Classic Foreign Movies                             https://www.netflix.com/browse/genre/32473"
echo "Classic Sci-Fi & Fantasy                           https://www.netflix.com/browse/genre/47147"
echo "Classic Thrillers                                  https://www.netflix.com/browse/genre/46588"
echo "Classic War Movies                                 https://www.netflix.com/browse/genre/48744"
echo "Classic Westerns                                   https://www.netflix.com/browse/genre/47465"
echo "Epics                                              https://www.netflix.com/browse/genre/52858"
echo "Film Noir                                          https://www.netflix.com/browse/genre/7687"
echo "Silent Movies                                      https://www.netflix.com/browse/genre/53310"
echo ""
echo "Comedy                                             https://www.netflix.com/browse/genre/6548"
echo "Dark Comedies                                      https://www.netflix.com/browse/genre/869"
echo "Foreign Comedies                                   https://www.netflix.com/browse/genre/4426"
echo "Late Night Comedies                                https://www.netflix.com/browse/genre/1402"
echo "Mockumentaries                                     https://www.netflix.com/browse/genre/26"
echo "Political Comedies                                 https://www.netflix.com/browse/genre/2700"
echo "Romantic Comedies                                  https://www.netflix.com/browse/genre/5475"
echo "Satires                                            https://www.netflix.com/browse/genre/4922"
echo "Screwball Comedies                                 https://www.netflix.com/browse/genre/9702"
echo "Slapstick Comedies                                 https://www.netflix.com/browse/genre/10256"
echo "Sports Comedies                                    https://www.netflix.com/browse/genre/5286"
echo "Stand-Up Comedy                                    https://www.netflix.com/browse/genre/11559"
echo "Teen Comedies                                      https://www.netflix.com/browse/genre/3519"
echo ""
echo "Documentaries                                      https://www.netflix.com/browse/genre/6839"
echo "Biographical Documentaries                         https://www.netflix.com/browse/genre/3652"
echo "Crime Documentaries                                https://www.netflix.com/browse/genre/9875"
echo "Foreign Documentaries                              https://www.netflix.com/browse/genre/5161"
echo "Historical Documentaries                           https://www.netflix.com/browse/genre/5349"
echo "Military Documentaries                             https://www.netflix.com/browse/genre/4006"
echo "Music & Concert Documentaries                      https://www.netflix.com/browse/genre/90361"
echo "Political Documentaries                            https://www.netflix.com/browse/genre/7018"
echo "Religious Documentaries                            https://www.netflix.com/browse/genre/10005"
echo "Science & Nature Documentaries                     https://www.netflix.com/browse/genre/2595"
echo "Social & Cultural Documentaries                    https://www.netflix.com/browse/genre/3675"
echo "Sports Documentaries                               https://www.netflix.com/browse/genre/180"
echo "Travel & Adventure Documentaries                   https://www.netflix.com/browse/genre/1159"
echo ""
echo "Drama                                              https://www.netflix.com/browse/genre/5763"
echo "Biographical Dramas                                https://www.netflix.com/browse/genre/3179"
echo "Classic Dramas                                     https://www.netflix.com/browse/genre/29809"
echo "Courtroom Dramas                                   https://www.netflix.com/browse/genre/528582748"
echo "Crime Dramas                                       https://www.netflix.com/browse/genre/6889"
echo "Dramas Based on Books                              https://www.netflix.com/browse/genre/4961"
echo "Dramas Based on Real Life                          https://www.netflix.com/browse/genre/3653"
echo "Foreign Dramas                                     https://www.netflix.com/browse/genre/2150"
echo "Gay & Lesbian Dramas                               https://www.netflix.com/browse/genre/500"
echo "Independent Dramas                                 https://www.netflix.com/browse/genre/384"
echo "Military Dramas                                    https://www.netflix.com/browse/genre/11"
echo "Period Pieces                                      https://www.netflix.com/browse/genre/12123"
echo "Political Dramas                                   https://www.netflix.com/browse/genre/6616"
echo "Romantic Dramas                                    https://www.netflix.com/browse/genre/1255"
echo "Showbiz Dramas                                     https://www.netflix.com/browse/genre/5012"
echo "Social Issue Dramas                                https://www.netflix.com/browse/genre/3947"
echo "Sports Dramas                                      https://www.netflix.com/browse/genre/7243"
echo "Tearjerkers                                        https://www.netflix.com/browse/genre/6384"
echo "Teen Dramas                                        https://www.netflix.com/browse/genre/9299"
echo ""
echo "Horror                                             https://www.netflix.com/browse/genre/8711"
echo "B-Horror Movies                                    https://www.netflix.com/browse/genre/8195"
echo "Creature Features                                  https://www.netflix.com/browse/genre/6895"
echo "Cult Horror Movies                                 https://www.netflix.com/browse/genre/10944"
echo "Deep Sea Horror Movies                             https://www.netflix.com/browse/genre/45028"
echo "Foreign Horror Movies                              https://www.netflix.com/browse/genre/8654"
echo "Goofy Horror Movies                                https://www.netflix.com/browse/genre/4021"
echo "Horror Comedy                                      https://www.netflix.com/browse/genre/89585"
echo "Monster Movies                                     https://www.netflix.com/browse/genre/947"
echo "Satanic Stories                                    https://www.netflix.com/browse/genre/6998"
echo "Slasher & Serial Killer Movies                     https://www.netflix.com/browse/genre/8646"
echo "Supernatural Horror Movies                         https://www.netflix.com/browse/genre/42023"
echo "Survival Horror                                    https://www.netflix.com/browse/genre/2939659"
echo "Teen Screams                                       https://www.netflix.com/browse/genre/52147"
echo "Vampire Horror Movies                              https://www.netflix.com/browse/genre/75804"
echo "Werewolf Horror Movies                             https://www.netflix.com/browse/genre/75930"
echo "Zombie Horror Movies                               https://www.netflix.com/browse/genre/75405"
echo ""
echo "Music                                              https://www.netflix.com/browse/genre/1701"
echo "Classic Musicals                                   https://www.netflix.com/browse/genre/32392"
echo "Country & Western/Folk                             https://www.netflix.com/browse/genre/1105"
echo "Disney Musicals                                    https://www.netflix.com/browse/genre/59433"
echo "Jazz & Easy Listening                              https://www.netflix.com/browse/genre/10271"
echo "Kids Music                                         https://www.netflix.com/browse/genre/52843"
echo "Latin Music                                        https://www.netflix.com/browse/genre/10741"
echo "Musicals                                           https://www.netflix.com/browse/genre/13335"
echo "Rock & Pop Concerts                                https://www.netflix.com/browse/genre/3278"
echo "Showbiz Musicals                                   https://www.netflix.com/browse/genre/13573"
echo "Stage Musicals                                     https://www.netflix.com/browse/genre/55774"
echo "Urban & Dance Concerts                             https://www.netflix.com/browse/genre/9472"
echo "World Music Concerts                               https://www.netflix.com/browse/genre/2856"
echo ""
echo "Romance                                            https://www.netflix.com/browse/genre/8883"
echo "Classic Romantic Movies                            https://www.netflix.com/browse/genre/31273"
echo "Quirky Romance                                     https://www.netflix.com/browse/genre/36103"
echo "Romantic Comedies                                  https://www.netflix.com/browse/genre/5475"
echo "Romantic Dramas                                    https://www.netflix.com/browse/genre/1255"
echo "Romantic Favorites                                 https://www.netflix.com/browse/genre/502675"
echo "Romantic Foreign Movies                            https://www.netflix.com/browse/genre/7153"
echo "Romantic Independent Movies                        https://www.netflix.com/browse/genre/9916"
echo "Steamy Romantic Movies                             https://www.netflix.com/browse/genre/35800"
echo ""
echo "Sci-Fi & Fantasy                                   https://www.netflix.com/browse/genre/1492"
echo "Action Sci-Fi & Fantasy                            https://www.netflix.com/browse/genre/1568"
echo "Alien Sci-Fi                                       https://www.netflix.com/browse/genre/3327"
echo "Classic Sci-Fi & Fantasy                           https://www.netflix.com/browse/genre/47147"
echo "Cult Sci-Fi & Fantasy                              https://www.netflix.com/browse/genre/4734"
echo "Fantasy Movies                                     https://www.netflix.com/browse/genre/9744"
echo "Foreign Sci-Fi & Fantasy                           https://www.netflix.com/browse/genre/6485"
echo "Sci-Fi Adventure                                   https://www.netflix.com/browse/genre/6926"
echo "Sci-Fi Dramas                                      https://www.netflix.com/browse/genre/3916"
echo "Sci-Fi Horror Movies                               https://www.netflix.com/browse/genre/1694"
echo "Sci-Fi Thrillers                                   https://www.netflix.com/browse/genre/11014"
echo ""
echo "Sports                                             https://www.netflix.com/browse/genre/4370"
echo "Baseball Movies                                    https://www.netflix.com/browse/genre/12339"
echo "Basketball Movies                                  https://www.netflix.com/browse/genre/12762"
echo "BMX & Extreme Riding                               https://www.netflix.com/browse/genre/4582"
echo "Boxing Movies                                      https://www.netflix.com/browse/genre/12443"
echo "Car & Motorsport Movies                            https://www.netflix.com/browse/genre/49944"
echo "Football Movies                                    https://www.netflix.com/browse/genre/12803"
echo "Martial Arts, Boxing & Wrestling                   https://www.netflix.com/browse/genre/6695"
echo "Soccer Movies                                      https://www.netflix.com/browse/genre/12549"
echo "Sports Comedies                                    https://www.netflix.com/browse/genre/5286"
echo "Sports Documentaries                               https://www.netflix.com/browse/genre/180"
echo "Sports Dramas                                      https://www.netflix.com/browse/genre/7243"
echo "Sports & Fitness                                   https://www.netflix.com/browse/genre/9327"
echo ""
echo "Thrillers                                          https://www.netflix.com/browse/genre/8933"
echo "Action Thrillers                                   https://www.netflix.com/browse/genre/43048"
echo "Classic Thrillers                                  https://www.netflix.com/browse/genre/46588"
echo "Crime Thrillers                                    https://www.netflix.com/browse/genre/10499"
echo "Foreign Thrillers                                  https://www.netflix.com/browse/genre/10306"
echo "Gangster Movies                                    https://www.netflix.com/browse/genre/31851"
echo "Independent Thrillers                              https://www.netflix.com/browse/genre/3269"
echo "Mysteries                                          https://www.netflix.com/browse/genre/9994"
echo "Political Thrillers                                https://www.netflix.com/browse/genre/10504"
echo "Psychological Thrillers                            https://www.netflix.com/browse/genre/5505"
echo "Sci-Fi Thrillers                                   https://www.netflix.com/browse/genre/11014"
echo "Spy Thrillers                                      https://www.netflix.com/browse/genre/9147"
echo "Steamy Thrillers                                   https://www.netflix.com/browse/genre/972"
echo "Supernatural Thrillers                             https://www.netflix.com/browse/genre/11140"
echo ""
echo "TV Shows                                           https://www.netflix.com/browse/genre/83"
echo "British TV Shows                                   https://www.netflix.com/browse/genre/52117"
echo "Classic TV Shows                                   https://www.netflix.com/browse/genre/46553"
echo "Crime TV Shows                                     https://www.netflix.com/browse/genre/26146"
echo "Cult TV Shows                                      https://www.netflix.com/browse/genre/74652"
echo "Food & Travel TV                                   https://www.netflix.com/browse/genre/72436"
echo "Kids TV                                            https://www.netflix.com/browse/genre/27346"
echo "Korean TV Shows                                    https://www.netflix.com/browse/genre/67879"
echo "Military TV Shows                                  https://www.netflix.com/browse/genre/25804"
echo "Miniseries                                         https://www.netflix.com/browse/genre/4814"
echo "Reality TV                                         https://www.netflix.com/browse/genre/9833"
echo "Science & Nature TV                                https://www.netflix.com/browse/genre/52780"
echo "Teen TV Shows                                      https://www.netflix.com/browse/genre/60951"
echo "TV Action & Adventure                              https://www.netflix.com/browse/genre/10673"
echo "TV Comedies                                        https://www.netflix.com/browse/genre/10375"
echo "TV Documentaries                                   https://www.netflix.com/browse/genre/10105"
echo "TV Dramas                                          https://www.netflix.com/browse/genre/11714"
echo "TV Horror                                          https://www.netflix.com/browse/genre/83059"
echo "TV Mysteries                                       https://www.netflix.com/browse/genre/4366"
echo "TV Sci-Fi & Fantasy                                https://www.netflix.com/browse/genre/1372"
echo ""
echo "Faith & Spirituality                               https://www.netflix.com/browse/genre/26835"
echo "Faith & Spirituality Movies                        https://www.netflix.com/browse/genre/52804"
echo "Spiritual Documentaries                            https://www.netflix.com/browse/genre/2760"
echo "Kids Faith & Spirituality                          https://www.netflix.com/browse/genre/751423"
echo ""
echo "Foreign                                            https://www.netflix.com/browse/genre/7462"
echo "African Movies                                     https://www.netflix.com/browse/genre/3761"
echo "Arabic Movies                                      https://www.netflix.com/browse/genre/107456"
echo "Argentinian Movies                                 https://www.netflix.com/browse/genre/100310"
echo "Art House Movies                                   https://www.netflix.com/browse/genre/29764"
echo "Australian Movies                                  https://www.netflix.com/browse/genre/5230"
echo "Belgian Movies                                     https://www.netflix.com/browse/genre/262"
echo "Bollywood Movies                                   https://www.netflix.com/browse/genre/5480"
echo "Brazilian Movies                                   https://www.netflix.com/browse/genre/100373"
echo "British Movies                                     https://www.netflix.com/browse/genre/10757"
echo "Canadian Movies                                    https://www.netflix.com/browse/genre/107519"
echo "Chinese Movies                                     https://www.netflix.com/browse/genre/3960"
echo "Classic Foreign Movies                             https://www.netflix.com/browse/genre/32473"
echo "Dutch Movies                                       https://www.netflix.com/browse/genre/10606"
echo "Eastern European Movies                            https://www.netflix.com/browse/genre/5254"
echo "Foreign Action & Adventure                         https://www.netflix.com/browse/genre/11828"
echo "Foreign Comedies                                   https://www.netflix.com/browse/genre/4426"
echo "Foreign Documentaries                              https://www.netflix.com/browse/genre/5161"
echo "Foreign Dramas                                     https://www.netflix.com/browse/genre/2150"
echo "Foreign Gay & Lesbian Movies                       https://www.netflix.com/browse/genre/8243"
echo "Foreign Horror Movies                              https://www.netflix.com/browse/genre/8654"
echo "Foreign Sci-Fi & Fantasy                           https://www.netflix.com/browse/genre/6485"
echo "Foreign Thrillers                                  https://www.netflix.com/browse/genre/10306"
echo "French Movies                                      https://www.netflix.com/browse/genre/58807"
echo "German Movies                                      https://www.netflix.com/browse/genre/58886"
echo "Greek Movies                                       https://www.netflix.com/browse/genre/61115"
echo "Indian Movies                                      https://www.netflix.com/browse/genre/10463"
echo "Irish Movies                                       https://www.netflix.com/browse/genre/58750"
echo "Italian Movies                                     https://www.netflix.com/browse/genre/8221"
echo "Japanese Movies                                    https://www.netflix.com/browse/genre/10398"
echo "Korean Movies                                      https://www.netflix.com/browse/genre/5685"
echo "Latin American Movies                              https://www.netflix.com/browse/genre/1613"
echo "Middle Eastern Movies                              https://www.netflix.com/browse/genre/5875"
echo "New Zealand Movies                                 https://www.netflix.com/browse/genre/63782"
echo "Romantic Foreign Movies                            https://www.netflix.com/browse/genre/7153"
echo "Russian                                            https://www.netflix.com/browse/genre/11567"
echo "Scandinavian Movies                                https://www.netflix.com/browse/genre/9292"
echo "Southeast Asian Movies                             https://www.netflix.com/browse/genre/9196"
echo "Spanish Movies                                     https://www.netflix.com/browse/genre/58741"
echo ""
echo "Cult Movies                                        https://www.netflix.com/browse/genre/7627"
echo "B-Horror Movies                                    https://www.netflix.com/browse/genre/8195"
echo "Campy Movies                                       https://www.netflix.com/browse/genre/1252"
echo "Cult Comedies                                      https://www.netflix.com/browse/genre/9434"
echo "Cult Horror Movies                                 https://www.netflix.com/browse/genre/10944"
echo "Cult Sci-Fi & Fantasy                              https://www.netflix.com/browse/genre/4734"
echo ""
echo "Gay & Lesbian Movies                               https://www.netflix.com/browse/genre/5977"
echo "Foreign Gay & Lesbian Movies                       https://www.netflix.com/browse/genre/8243"
echo "Gay & Lesbian Comedies                             https://www.netflix.com/browse/genre/7120"
echo "Gay & Lesbian Documentaries                        https://www.netflix.com/browse/genre/4720"
echo "Gay & Lesbian Dramas                               https://www.netflix.com/browse/genre/500"
echo "Gay & Lesbian TV Shows                             https://www.netflix.com/browse/genre/65263"
echo "Romantic Gay & Lesbian Movies                      https://www.netflix.com/browse/genre/3329"
echo ""
echo "Independent Movies                                 https://www.netflix.com/browse/genre/7077"
echo "Experimental Movies                                https://www.netflix.com/browse/genre/11079"
echo "Independent Action & Adventure                     https://www.netflix.com/browse/genre/11804"
echo "Independent Comedies                               https://www.netflix.com/browse/genre/4195"
echo "Independent Dramas                                 https://www.netflix.com/browse/genre/384"
echo "Independent Thrillers                              https://www.netflix.com/browse/genre/3269"
echo "Romantic Independent Movies                        https://www.netflix.com/browse/genre/9916"
echo ""
echo "Recently Added                                     https://www.netflix.com/browse/genre/1592210"
echo "Short-Ass Movie                                    https://www.netflix.com/browse/genre/81603903"
echo "90-Minute Movies                                   https://www.netflix.com/browse/genre/81466194"
echo "Two-Hour Movies                                    https://www.netflix.com/browse/genre/81396426"
   shift
   exit
   ;;
  **)
   ;;
 esac
 shift # This makes $4=$5, $5=$6...
done


# --getlist
if [ "$listURL" != "" ]; then
 if [[ "$listURL" == *title* ]]; then        # When argument is just one movie, not the entire genre list...
  year=$(wget --no-check-certificate -q -O - "$listURL"          | tr '{' '\n'   | grep "latestYear"   | sed -n 's/.*"latestYear":\([0-9]\{4\}\).*/\1/p' )
  title=$(wget --no-check-certificate -q -O - "$listURL"         | tr '{' '\n'   | grep "^\"title\":"   | sed -E 's/^"title":"([^"]*)".*/\1/' | head -1)
  title=$(printf '%b\n' "$title")
  printf "%-50s  %-6s  %s\n" "$title" "${year:-NA}" "$listURL"

 else  
  genre=$(wget --no-check-certificate -q -O - "$listURL" | tr '{' '\n'| grep '"@type":"ItemList","name":' | tr ':' '\n'  | tr ',' '\n' | awk '/name/{getline; print}')
  echo "#List of moves in genre $genre :  $listURL"
  echo
  #wget --no-check-certificate -q -O - "$listURL" | tr '{' '\n'| grep '"@type":"Movie","name":' | tr ':' '\n'  | tr ',' '\n' | awk '/name/{getline; print}'  | sort  | uniq
  #wget --no-check-certificate -q -O - "$listURL" | tr '{' '\n'| grep '"@type":"Movie","name":' | tr ':' '\n'  | tr ',' '\n' |  awk '/name/{getline; title=$0; } /url/ {getline; url=$0; getline; url=url ":" $0; sub(/}}.*/,"",url);     gsub(/["]/,"",url);    printf ("%-50s  %-50s\n" , title, url) } ' | sort | uniq 
  #wget --no-check-certificate -q -O - "$listURL" | tr '{' '\n'| grep '"@type":"Movie","name":' | tr ',' '\n'|  awk '/name/{ title=$0; gsub(/"name":/,"",title); } /url/ {url=$0; getline; url=url ":" $0; sub(/}}.*/,"",url);  gsub(/"url":/,"",url);  gsub(/["]/,"",url);    printf ("%s\t%s\n" , title, url) } ' | sort | uniq  > movies.tsv

  json=$(wget --no-check-certificate -q -O - "$listURL" | tr '<>' '\n\n' | grep "@context")
  #echo "json: $json"                           # The entire JSON array 
  #echo "$json" | jq -r '.itemListElement[] '     # Only the .itemListElement array, which is the list of movies for this genre
  #echo "$json" | jq --raw-output '.itemListElement[] | select(.item["@type"] == "Movie")  | "\"\(.item.name)\" \t  \(.item.url)"  ' | sort | uniq > movies.tsv  # Explicitly look for type == "Movie"
  echo "$json" | jq --raw-output '.itemListElement[]   | "\"\(.item.name)\" \t  \(.item.url)"  ' |  sort -u  > movies.tsv   # More flexible

  # PARALLELIZATION (one wget per core)
  while IFS=$'\t' read -r title url; do
       ( year=$(wget -q -O - $url | sed -n 's/.*"latestYear":\([0-9]\{4\}\).*/\1/p' | head -1)
       printf "%-70s  %-6s  %s\n" "$title" "${year:-NA}" "$url"  ) &   # Each () & is a separate background subshell
   # This limits the number of concurrent jobs running in the background in parallel (jobs -rp)
   while (( `jobs -rp | wc -l` >= `nproc`  )); do sleep 0.1; done
  done < movies.tsv
  wait
  rm movies.tsv 
 fi

 exit
fi

website="imdb"
#website="rottentomatoes"

#""""""""""""""""""""""""""""""""""""""""""""""""""""""#
# Create the list of movies from Netflix categories    #
#""""""""""""""""""""""""""""""""""""""""""""""""""""""#
category="https://www.netflix.com/browse/genre/8933?bc=34399"  # thriller movies
category="https://www.netflix.com/browse/genre/5977?bc=34399"  # LGBTQ movies
category="https://www.netflix.com/browse/genre/5824?bc=34399"  # crime movies
category="https://www.netflix.com/browse/genre/78367?bc=34399" # international movies
category="https://www.netflix.com/browse/genre/7077?bc=34399" # international movies
category="https://www.netflix.com/browse/genre/5763?bc=34399" # drama movies
category="https://www.netflix.com/browse/genre/7627?bc=34399" # cult     
category="https://www.netflix.com/browse/genre/6548?bc=34399" # comedy 
category="https://www.netflix.com/browse/genre/31574?bc=34399" # classics 
category="https://www.netflix.com/browse/genre/1492?bc=34399" # fiction
category="https://www.netflix.com/browse/genre/3063?bc=34399" # anime  
category="https://www.netflix.com/browse/genre/1365?bc=34399" # action
category="https://www.netflix.com/browse/genre/8711?bc=34399"  # horror movies
#wget --no-check-certificate -q -O - "$category" | tr '{' '\n'| grep '"@type":"Movie","name":' | tr ':' '\n'  | tr ',' '\n' | awk '/name/{getline; print}'  | sort | uniq
#exit



# USE googler TO SEARCH IMDB AND PARSE RESULTS
if [ "$website" == "imdb" ]; then
 ff=tmp.$$
 cat $list | while read movie
 do
  googler -C  "$movie imdb" --noprompt > $ff 2>&1

  if [ "$debug" == 1 ]; then
   echo "THIS IS THE GOOGLER SEARCH:" 
   echo "googler -C  "$movie imdb" --noprompt"
   echo "URL: $URL"
   echo "------------------------------------"
   head $ff
  fi

  URL="$( grep title $ff )"
  if [ "$(grep "No results" $ff)" != "" ]; then
   printf "%-10s  %-50s  %-50s\n"  "0.0" "$movie" "---Not-found---"
   continue
  fi
  #rating=$(wget --no-check-certificate --user-agent=\"Mozilla\" -q -O - $URL | grep -m 1 ratingValue | awk '{gsub("\"","", $0); print $NF}')
  rating=$(wget --no-check-certificate --user-agent=\"Mozilla\" -q -O - $URL | grep  ratingValue  | awk '{gsub(",","\n", $0); print }' |grep ratingValue | tr ':' ' ' | tr '}' ' ' | awk 'END{print $NF}')
  if [ "$rating" != "" ]; then
   printf "%-10s  %-50s  %-50s\n"  "$rating" "$movie" "$URL"
  else
   printf "%-10s  %-50s  %-50s\n"  "0.0" "$movie" "---Not-found---"
  fi
 done
 rm $ff

elif [ "$website" == "rottentomatoes" ]; then
 cat $list | while read movie
 do
 name=$(echo $movie | sed -e 's/"//g' -e 's/ /_/g' | awk '{print tolower($0)}' )
 URL="https://www.rottentomatoes.com/m/${name}"
 #echo "Looking for  $name in $URL"
 if [ "`wget --no-check-certificate -q -O - $URL | wc -l`" != "0" ]; then
  wget --no-check-certificate -q -O - $URL | awk -v mov="${URL}" '
   /og:title/{
     gsub("            <meta property=\"og:title\" content=\"","",$0);
     gsub("\">","",$0);  title=$0}
   /percentage--audience mop/{
     getline;
     gsub("%"," %",$NF);
     printf("%-10s  %-50s  %-50s\n", $NF,title,mov)}
   /audienceAll/{
   gsub(",","\n",$0);
   for (j=0;j<NF;j++) if ( $(NF-j) ~ "scoreType" ) score=$(NF-j+1);
   gsub("\"","",score); gsub("score:","",score);
   printf("%-10s   %-50s  %-50s\n", score,title,mov)} '

 else
  printf "%-10s  %-50s  %-50s\n"  "0.0" "$movie" "---Not-found---"
 fi
 done
fi

if [ -f tmp.tmp ]; then
 rm tmp.tmp
fi
