# How This Works

This page explains how the movie lists on this site are generated from Netflix and IMDb data.  
All scripts are included in this repository, so you can reproduce or update the lists yourself.

---

## 🎬 Pipeline Overview

1. **Pick a Netflix genre**: each list corresponds to a Netflix genre URL, e.g.,  
   `https://www.netflix.com/browse/genre/8711` for *Essential Horror Flicks*.
2. **Run the main script**:  

```bash
./scripts/rate_them_all_IMDb.sh <Netflix-genre-URL>
```


