# Horror Movies on Netflix

This page lists horror movies currently available on Netflix, together with their IMDb ratings.

The data shown here is generated automatically using the scripts included in the repository.

---

## Horror movie list (IMDb ratings)

```text
(Generated file: data/list_Essential_Horror_Flicks_rating_imdb.txt)
```

## How this list is generated
This list is produced by the following pipeline:

```
./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/8711 
```

which internally calls:
```
imdb-rating_omdbapi.sh
```

The raw data file displayed above is:
```text
data/list_Essential_Horror_Flicks_rating_imdb.txt
```


