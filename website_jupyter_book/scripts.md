# Scripts

Here I provide all the scripts for this project, which you can also find here: https://github.com/fgonzcat/Netfilx_IMDb_movie_ratings/

## rate_them_all_IMDb.sh
```{literalinclude} ../scripts/rate_them_all_IMDb.sh
:language: bash
:linenos:
```

### Example
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
See the resulting nicer list in [Cult Movies list](cult).

## imdb-rating_omdbapi.sh

```{literalinclude} ../scripts/imdb-rating_omdbapi.sh
:language: bash
:linenos:
```

### Example
```bash
./imdb-rating_omdbapi.sh ../data/list_Cult_Movies.txt
```

The list above was originally generated with

```bash
 ./imdb-rating.sh --getlist https://www.netflix.com/browse/genre/7627 > ../data/list_Cult_Movies.txt
```
