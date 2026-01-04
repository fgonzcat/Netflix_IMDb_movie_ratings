# Netflix Movies with IMDb Ratings

Welcome.

This website presents curated lists of Netflix movies, organized by genre,
together with their IMDb ratings. All lists are generated automatically from
public data sources using reproducible scripts.

The goal of this project is twofold:

1. To provide an up-to-date, easy-to-browse overview of Netflix movies by category.
2. To show *exactly* how these lists are generated, so anyone can reproduce
   or modify them on their own machine.

---

## What you will find here

Each category in the menu on the left (Horror, Comedy, Thrillers, etc.)
corresponds to a specific, automatically generated list of movies.

For each category, the page shows:
- The movie titles
- Their IMDb ratings
- The raw output produced by the scripts

No manual curation or hand editing is performed.

---

## How the data is generated

All movie lists shown on this website are generated locally using shell scripts
included in the repository.

In short, the workflow is:

1. Retrieve lists of Netflix movies by category
2. Query IMDb ratings using the OMDb API
3. Post-process and format the results
4. Publish the output as a static website

You can reproduce everything you see here by cloning the repository and running:

```bash
./scripts/rate_them_all_IMDb.sh


```{tableofcontents}
```
