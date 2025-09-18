#!/bin/sh
set -u

echo Starting build script...

command -v pandoc >/dev/null 2>&1 || { echo "pandoc is not installed"; exit 1; }
command -v sed    >/dev/null 2>&1 || { echo "sed is not installed"; exit 1; }

echo "pandoc and sed found"

MD_DIR="markdown"
RES_DIR="resources"

# Only define this if it's not already defined
: "${OUTPUT_DIR="output"}"

# Make sure this exists before we start trying to put stuff there
mkdir $OUTPUT_DIR

# Collect all markdown files
PAGES=$(ls $MD_DIR/*.md)

echo Found pages:
echo $PAGES

# Build navbar
nav=""
for f in $PAGES; do
	title=$(sed -n 's/^title:[[:space:]]*//p' "$f")
	page=$(basename "$f" .md).html
	if [ -n "$nav" ]; then
		nav="$nav | "
	fi
	nav="$nav<a href=\"$page\">$title</a>"
done

echo Navbar generated:
echo $nav

# Build each page
for f in $PAGES; do
	name=$(basename "$f" .md)
	pandoc "$f" -o "$OUTPUT_DIR/$name.html" \
		--template="template.html" \
		-V navbar="$nav"
	echo Generated page $name.html in directory $OUTPUT_DIR
done

# Copy extra stuff to output
cp -r $RES_DIR/. $OUTPUT_DIR

echo Done