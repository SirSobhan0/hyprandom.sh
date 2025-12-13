#!/bin/bash

# A silent script to fetch and set wallpapers for Hyprland from various sources.
# It only produces output on error, making it suitable for background services and Waybar.

# --- Configuration ---
# IMPORTANT: set your apikeys in the apikeys file.
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
FAV_DIR="$WALLPAPER_DIR/favourite"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the wallpaper directory if it doesn't exist
mkdir -p "$FAV_DIR"
[[ -f "$SCRIPT_DIR/apikeys" ]] && source $SCRIPT_DIR/apikeys

# --- Default Values ---
SOURCE="wallhaven"
NSFW=false

# --- Functions ---

usage() {
    # Usage information is still useful for manual runs
    echo "Usage: $(basename "$0") [-s <source>] [-u] [-m] [-h]"
    echo "Options:"
    echo "  -s <source>   Specify wallpaper source."
    echo "  -u            Use unsafe mode (enables sketchy/NSFW)."
    echo "  -q            Use custom query for supported sources/url for fetching from url."
    echo "  -h            Display this help message."
    exit 1
}

fetch_from_wallhaven() {

    random_wallpaper_index=$(( RANDOM % 24 ))
    PURITY="100"       # 100=SFW, 111=SFW+Sketchy+NSFW
    CATEGORIES="110"   #  111=general/anime/people
    SEED=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c6)

    if $NSFW; then
        QUERY_TERMS=("${QUERY_TERMS_NSFW[@]}")
        PURITY="011"
    fi

    if [ -z "$WALLHAVEN_API_KEY" ]; then
        wallpaper_url=$(curl -s "https://wallhaven.cc/api/v1/search?categories=${CATEGORIES}&purity=${PURITY}&seed=${SEED}&q=${CUSTOM_QUERY}" | jq -r ".data[${random_wallpaper_index}].path")
    else
        wallpaper_url=$(curl -s "https://wallhaven.cc/api/v1/search?apikey=${WALLHAVEN_API_KEY}&categories=${CATEGORIES}&purity=${PURITY}&seed=${SEED}&q=${CUSTOM_QUERY}" | jq -r ".data[${random_wallpaper_index}].path")
    fi
    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_unsplash() {
    safety=high

    if $NSFW; then
	safety=low
    fi

    wallpaper_url=$(curl -s "https://api.unsplash.com/photos/random/?client_id=${UNSPLASH_CLIENT_ID}&orientation=landscape&content_filter=${safety}&query=${CUSTOM_QUERY}" | jq -r ".urls.full")
    
    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    file_name=${wallpaper_url##*/}
    file_name=${file_name%%\?*}.jpg

    curl -sS --fail -o ${file_name} --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/${file_name}"
}

fetch_from_konachan() {
    random_wallpaper_index=$(( RANDOM % 21 ))
    random_page_index=$(( RANDOM % 15221 ))
    url=net

    if $NSFW; then
        url=com
    fi

    wallpaper_url=$(curl -s "https://konachan.${url}/post.json?page=${random_page_index}" | jq  -r ".[${random_wallpaper_index}].file_url")

    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_gelbooru() {
    random_wallpaper_index=$(( RANDOM % 42 ))
    random_page_index=$(( RANDOM % 476 ))

    wallpaper_url=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&pid=${random_page_index}&limit=42&json=1&api_key=${GELBOORU_API_KEY}&user_id=${GELBOORU_USERID}" | jq -r ".post[${random_wallpaper_index}].file_url")
    
    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_waifuim() {
    wallpaper_url=$(curl -s "https://api.waifu.im/search?is_nsfw=${NSFW}" | jq -r '.images.[0].url')
    
    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_waifupics() {
    QUERY_TERMS=("waifu" "neko" "bully" "cuddle" "cry" "hug" "awoo" "kiss" "lick" "pat" "smug" "bonk" "yeet" "blush" "smile" "wave" "highfive" "handhold" "nom" "bite" "glomp" "slap" "kill" "kick" "happy" "wink" "poke")
    QUERY_TERMS_NSFW=("waifu" "neko" "blowjob")

    if $NSFW; then
	NSFW="nsfw"
        QUERY_TERMS=("${QUERY_TERMS_NSFW[@]}")
    else
        NSFW="sfw"
    fi

    random_query=${QUERY_TERMS[$(( RANDOM % ${#QUERY_TERMS[@]} ))]}

    wallpaper_url=$(curl -s "https://api.waifu.pics/${NSFW}/${random_query}" | jq -r '.url')
    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_yandere() {
    random_wallpaper_index=$(( RANDOM % 10 ))
    random_page_index=$(( RANDOM % 72000 ))

    wallpaper_url=$(curl -s "https://yande.re/post.json?page=${random_page_index}&limit=10" | jq -r ".[${random_wallpaper_index}].file_url")

    if [ -z "$wallpaper_url" ] || [ "$wallpaper_url" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/$(basename "$wallpaper_url")"
}

fetch_from_nekosmoe() {

    wallpaper_id=$(curl -H "Authorization: ${NEKOS_TOKEN}" "https://nekos.moe/api/v1/random/image?nsfw=${NSFW}" | jq -r ".images[].id")
    
    if [ -z "$wallpaper_id" ] || [ "$wallpaper_id" == "null" ]; then
        echo "Error: Failed to get a wallpaper URL. Check your query or API key." >&2
        exit 1
    fi

    wallpaper_url="https://nekos.moe/image/${wallpaper_id}"
    
    file_name=nekos_${wallpaper_id}.jpg

    curl -sS --fail -o ${file_name} --output-dir "$WALLPAPER_DIR" "$wallpaper_url"

    echo "$WALLPAPER_DIR/${file_name}"
}

fetch_from_url() {
    curl -sS --fail -O --output-dir "$WALLPAPER_DIR" "$CUSTOM_QUERY"
    echo "$WALLPAPER_DIR/$(basename "$CUSTOM_QUERY")"
}

fetch_from_local() {
    wallpaper_path=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

    if [ -z "$wallpaper_path" ]; then
        echo "Error: No image files found in $WALLPAPER_DIR." >&2
        exit 1
    fi

    echo "$wallpaper_path"
}

fetch_from_fav() {
    wallpaper_path=$(find "$FAV_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

    if [ -z "$wallpaper_path" ]; then
        echo "Error: No image files found in $WALLPAPER_DIR." >&2
        exit 1
    fi

    echo "$wallpaper_path"
}

while getopts "s:umq:h" opt; do
  case ${opt} in
    s)
      SOURCE=$OPTARG
      ;;
    u)
      NSFW=true
      ;;
    m)
      MILF=true
      ;;
    q)
      CUSTOM_QUERY=$OPTARG
      ;;
    h)
      usage
      ;;
    \?)
      usage
      ;;
  esac
done


WALLPAPER=""

case $SOURCE in
  "wallhaven")
    WALLPAPER=$(fetch_from_wallhaven)
    ;;
  "unsplash")
    WALLPAPER=$(fetch_from_unsplash)
    ;;
  "konachan")
    WALLPAPER=$(fetch_from_konachan)
    ;;
  "waifuim")
    WALLPAPER=$(fetch_from_waifuim)
    ;;
  "waifupics")
    WALLPAPER=$(fetch_from_waifupics)
    ;;
  "gelbooru")
    WALLPAPER=$(fetch_from_gelbooru)
    ;;
  "yandere")
    WALLPAPER=$(fetch_from_yandere)
    ;;
  "nekos")
    WALLPAPER=$(fetch_from_nekosmoe)
    ;;
  "url")
    WALLPAPER=$(fetch_from_url)
    ;;
  "local")
    WALLPAPER=$(fetch_from_local)
    ;;
  "fav")
    WALLPAPER=$(fetch_from_fav)
    ;;
  *)
    echo "Error: Invalid source specified." >&2
    usage
    ;;
esac


if [ -f "$WALLPAPER" ]; then
    if file --mime-type "$WALLPAPER" | grep -q 'image/gif'; then
	convert "$WALLPAPER[0]" "${WALLPAPER}.png"
	WALLPAPER="${WALLPAPER}.png"
    fi
    ln -sf "$WALLPAPER" "$WALLPAPER_DIR/current.png"
    hyprctl hyprpaper preload "$WALLPAPER"
    hyprctl hyprpaper wallpaper ",$WALLPAPER"
    hyprctl hyprpaper unload all
else
    if [ ! -z "$WALLPAPER" ]; then
        echo "Error: Final wallpaper path is not a valid file: $WALLPAPER" >&2
    fi
    exit 1
fi

exit 0
