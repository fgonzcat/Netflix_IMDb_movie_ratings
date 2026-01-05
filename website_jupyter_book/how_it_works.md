# How This Works

This page explains how I generated the movie lists on this site from Netflix and IMDb data.
All scripts are included in this repository, so you can reproduce or update the lists yourself. Just look at the icon above https://github.com/fgonzcat/Netfilx_IMDb_movie_ratings/


---

## 🔍 Where the data comes from
This project combines two public data sources:
1. **Netflix genre pages**  
   Netflix exposes genre-based browsing pages such as:
   ```
   https://www.netflix.com/browse/genre/8711
   ```
   These pages list all movies currently available in a given category (e.g. Horror Movies). Read more [here](https://www.netflix-codes.com).
2. **IMDb ratings, accessed via the OMDb API**  
   IMDb does not provide a free public API directly. Instead, this project uses OMDb (Open Movie Database), a community-maintained API that mirrors IMDb data.

---

## 🔑 OMDb Key: what you need to know
To fetch IMDb ratings automatically, you need an OMDb API key.
```{note}
OMDb is free for personal use, but **you must request your own API key**.
```

### How to get an OMDb API key
1. Go to:  <a href="https://www.omdbapi.com/" target="_blank">https://www.omdbapi.com/</a>
2. Click “API Key”
3. Request a free key (email-based)
4. You’ll receive a key like:
   ```
   abc12345
   ```

### Where the key is used
The script `imdb-rating_omdbapi.sh` makes requests like:
```ruby
http://www.omdbapi.com/?t=Movie+Title&apikey=YOUR_KEY
```
You must replace this key in the variable `APIKEY` of the `imdb-rating_omdbapi.sh` script.

### Query example in OMDb
Just visiting the URL [http://www.omdbapi.com/?t="Battlefield%20Earth"%20%20&y=2000&apikey=1a8c9011](http://www.omdbapi.com/?t="Battlefield%20Earth"%20%20&y=2000&apikey=1a8c9011) or executing
```ruby
curl -s "http://www.omdbapi.com/?t="Battlefield%20Earth"%20%20&y=2000&apikey=1a8c9011"
```
in your terminal will show you the following output:
```text
{"Title":"Battlefield Earth","Year":"2000","Rated":"PG-13","Released":"12 May 2000","Runtime":"117 min","Genre":"Action, Adventure, Sci-Fi","Director":"Roger Christian","Writer":"Corey Mandell, J.D. Shapiro, L. Ron Hubbard","Actors":"John Travolta, Forest Whitaker, Barry Pepper","Plot":"It's the year 3000 A.D., and the Earth is lost to the alien race of Psychlos. Humanity is enslaved by these gold-thirsty tyrants, who are unaware that their 'man-animals' are about to ignite the rebellion of a lifetime.","Language":"English","Country":"United States, Canada","Awards":"19 wins & 3 nominations total","Poster":"https://m.media-amazon.com/images/M/MV5BODJiODc1NjQtZmRhZS00ZTlmLTlmNTItMmZiZjcxMmU4ZDI2XkEyXkFqcGc@._V1_SX300.jpg","Ratings":[{"Source":"Internet Movie Database","Value":"2.5/10"},{"Source":"Rotten Tomatoes","Value":"3%"},{"Source":"Metacritic","Value":"9/100"}],"Metascore":"9","imdbRating":"2.5","imdbVotes":"84,567","imdbID":"tt0185183","Type":"movie","DVD":"N/A","BoxOffice":"$21,471,685","Production":"N/A","Website":"N/A","Response":"True"}
```
which corresponds to the OMDb details of the movie **Battlefield Earth** that you can see in the URL above, released in the year 2000, using the API key `1a8c9011`.


```{warning}
A **free OMDb API key** is limited to **1,000 requests per day**.

If you end up querying ratings for more than ~1,000 movies in a single day, you may hit this limit. In that case, you can request an additional free key using a different email address and replace it in the `imdb-rating_omdbapi.sh` script.
```

---

## ⚡ Quick start (5 commands)

If you just want to generate a ranked Netflix list as fast as possible:

```bash
# 1. Clone the repository
git clone https://github.com/fgonzcat/Netfilx_IMDb_movie_ratings.git
cd Netfilx_IMDb_movie_ratings

# 2. Make scripts executable
chmod +x *.sh

# 3. Edit the OMDb API key inside the script
vim scripts/imdb-rating_omdbapi.sh    # replace the variable APIKEY="your_omdb_api_key_here"

# 4. Run the pipeline for a Netflix genre
./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/8711

# 5. Check the generated output
ls data/
```

The ranked movie list will appear in the data/ folder.


---

## 🔄 Diagram-style pipeline

```text
Netflix genre URL
        |
        v
+---------------------+
| wget (HTML scrape)  |
+---------------------+
        |
        v
Extract movie titles
        |
        v
+---------------------------+
| OMDb API (IMDb ratings)   |
+---------------------------+
        |
        v
Raw text data (data/)
        |
        v
+---------------------------+
| Markdown table generator  |
+---------------------------+
        |
        v
Rendered movie lists
(this website)
```


---

## 🎬 Pipeline Overview

Once the OMDb key is available, the full workflow looks like this:
1. **Pick a Netflix genre**:
   Each list corresponds to a Netflix genre URL, for example:
   ```
   https://www.netflix.com/browse/genre/8711
   ```
2. **Run the main script**:
   ```
   ./rate_them_all_IMDb.sh <Netflix-genre-URL>
   ```
3. **Example**
   ```
   ./rate_them_all_IMDb.sh https://www.netflix.com/browse/genre/8711
   ```

### ⚙️ What the scripts actually do
The main script proceeds in several steps:

- 📥 Scrape Netflix  
   Uses `wget` to download the genre page HTML and extract movie titles.
- 🔎 Query OMDb  
  For each title, the script:
  - Calls the OMDb API
  - Retrieves IMDb rating, year, and IMDb ID
- 🧾 Generate raw data  
  Outputs a plain text file in the data/ directory containing:
  - IMDb rating
  - Movie title
  - Year
  - IMDb link
  - Netflix link

## 📊 From raw data to tables
The raw output is then converted into clean Markdown tables like this:

| IMDb ⭐ | Title | IMDb | Netflix |
|:-------:|:------|------|---------|
| 8.8 | *title* | https://www.imdb.com/title/<imdb_title> | https://www.netflix.com/title/<netflix_title> |
| 7.5 | *title* | https://www.imdb.com/title/<imdb_title> | https://www.netflix.com/title/<netflix_title> |
| . | *.* | . | . |

These tables are what you see rendered on the site.


## 🛠 Scripts Overview
- `rate_them_all_IMDb.sh` – Main pipeline script — coordinates everything
- `imdb-rating_omdbapi.sh` – Queries the OMDb API for IMDb ratings
- `imdb-rating.sh` – Extracts movie titles from Netflix genre pages
- `highest_rated_ones_only.sh` – Optional: Filters and generates top-rated subsets (not used in the main pipeline)


```{warning}
All scripts must remain in the same directory when running the main pipeline, because relative paths are assumed.
```

## 📁 Data transparency
```{note}
All intermediate and final data files are stored in the `data/` directory. Nothing is hidden — you can inspect, modify, or regenerate everything.
```

## 🚫 Disclaimer
This project is not affiliated with Netflix, IMDb, or OMDb. All trademarks belong to their respective owners.
