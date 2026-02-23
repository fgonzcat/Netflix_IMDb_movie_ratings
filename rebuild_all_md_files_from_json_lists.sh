#!/bin/bash



for genre in  `awk '/Movie Categories/{bool=1}  bool && /file/{print $NF}' website_jupyter_book/_toc.yml`
do
  json="website_jupyter_book/_static/data/$genre.json"
  md="website_jupyter_book/$genre.md"
  echo "./scripts/json_to_md.py  $json > $md"
  ./scripts/json_to_md.py  $json >  $md
done

./scripts/json_to_md.py website_jupyter_book/_static/data/best.json  > website_jupyter_book/best.md
