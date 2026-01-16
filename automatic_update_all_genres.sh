#!/bin/bash

#############################
#  This code basically runs
#  ./scripts/update-genre i for each i in genre
#
#  There will probably hundreds of calls to OMDb so be careful.
# ./scripts/update-genre has an emergency exit route when you exceed the limit that makes this script stop.
############################

INTERACTIVE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interactive)
            INTERACTIVE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done
export INTERACTIVE   # <-- now child scripts can see it



genres=$(awk '/Movie Categories/{bool=1}  /file/ && bool==1{print $NF} ' website_jupyter_book/_toc.yml)

for g in $genres
do
 md=$(echo website_jupyter_book/${g}.md) 
 netflix_url=$(grep "Netflix genre:"  $md | tr '"' '\n' |grep netflix | head -1)

 echo -e "\n\033[34m==>\033[0m \033[1mGENRE: \033[0m \033[36m $g \033[0m"
 echo "./scripts/update_genre.sh $g  $netflix_url"
 ./scripts/update_genre.sh $g  $netflix_url   || {
    echo "Stopping automatic update: OMDb limit or fatal error." >&2
    exit 1
  }
done
