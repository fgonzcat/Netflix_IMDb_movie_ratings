# How This Works

This page explains how the movie lists on this site are generated from Netflix and IMDb data.  
All scripts are included in this repository, so you can reproduce or update the lists yourself.

---

## 🎬 Pipeline Overview

1. **Pick a Netflix genre**: each list corresponds to a Netflix genre URL, e.g.,  
   `https://www.netflix.com/browse/genre/8711` for *Essential Horror Flicks*.
2. **Run the main script**:  

```bash
./rate_them_all_IMDb.sh <Netflix-genre-URL>
```
3.  **Example**:
./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/8711


This script will:
- Use `wget` to read the html code from the Netflix page and retrieve all the titles of movies it can find for that genre.
- Call `imdb-rating_omdbapi.sh` to get IMDb ratings for each movie.
- Generate a simple text file in the data/ folder with ratings, titles, year, and links to the respective IMDb and Netflix websites.


I converted those tables in a nice Markdown table with columns like this one:

| IMDb ⭐ | Title | IMDb | Netflix |
|:-------:|:------|------|---------|
| 8.8 | *title* | https://www.imdb.com/title/<imdb_title> | https://www.netflix.com/title/<netflix_title> |
| 7.5 | *title* | https://www.imdb.com/title/<imdb_title> | https://www.netflix.com/title/<netflix_title> |
| . | *.* | . | . |

## 🛠 Scripts Overview
- `rate_them_all_IMDb.sh` – main pipeline script that calls the others
- `imdb-rating_omdbapi.sh` – fetches IMDb ratings using the OMDb API
- `imdb-rating.sh` – helper for Netflix scraping and getting the list of movies of a given genre.
- `highest_rated_ones_only.sh` – generates top-rated subset


```{warning}
Keep all scripts in the same folder when running the main script, because rate_them_all_IMDb.sh expects relative paths. The lists can be in a different directory, as long as you provide the path to them.
```

```{note}
For more technical users, the raw data is always available in the data/ folder of this repository.
```

