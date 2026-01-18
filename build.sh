#!/bin/sh
set -u

echo Starting build script...

command -v pandoc >/dev/null 2>&1 || { echo "pandoc is not installed"; exit 1; }
command -v sed    >/dev/null 2>&1 || { echo "sed is not installed"; exit 1; }
command -v yq     >/dev/null 2>&1 || { echo "yq is not installed"; exit 1; }

echo "pandoc, sed, and yq found"

SRC_DIR="site"
RES_DIR="resources"

# Only define this if it's not already defined
: "${OUTPUT_DIR="output"}"

# Make sure this exists before we start trying to put stuff there
mkdir $OUTPUT_DIR
rm -rf $OUTPUT_DIR/*

echo Created and cleaned output directory $OUTPUT_DIR

# Collect all markdown files
PAGES=$(ls $SRC_DIR/*.md)

echo Found pages:
echo $PAGES

# Build navbar
nav=""
tmp=$(mktemp)

# Build weird name thingy so that they're ordered properly
for f in $PAGES; do
    idx=$(sed -n '/^---$/,/^---$/p' $f | sed '/^---$/d' | yq -r '.index')
    title=$(sed -n '/^---$/,/^---$/p' $f | sed '/^---$/d' | yq -r '.title')
    page=$(basename "$f" .md).html
    echo "$idx|$title|$page" >> "$tmp"
done

# Sort by index
sort -n "$tmp" > "$tmp.sorted"

while IFS="|" read -r idx title page; do
    [ -n "$nav" ] && nav="$nav | "
    nav="$nav<a href=\"$page\">$title</a>"
done < "$tmp.sorted"

rm "$tmp" "$tmp.sorted"


echo Navbar generated:
echo $nav

# Build each page
for f in $PAGES; do
	name=$(basename "$f" .md)
	pandoc "$f" -o "$OUTPUT_DIR/$name.html" \
		--template="template.html" \
		-V navbar="$nav" \
        -V head-content="$(cat head-content.html)" \
        -V foot-content="$(cat foot-content.html)"
	echo Generated page $name.html in directory $OUTPUT_DIR
done

# Copy non-markdown files from SRC_DIR
find "$SRC_DIR" -type f ! -name '*.md' | while IFS= read -r f; do
    out="$OUTPUT_DIR/${f#$SRC_DIR/}"
    mkdir -p "$(dirname "$out")"
    cp "$f" "$out"
    echo Copied file $out
done

# Copy extra stuff to output
cp -r $RES_DIR/. $OUTPUT_DIR

echo Done