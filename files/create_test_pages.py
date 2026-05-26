#!/usr/bin/env python3
"""
Generate synthetic HTML test pages that mirror the Google carousel structure
used in van-gogh-paintings.html (same CSS classes, same JS image-loading pattern).
These are used to verify the extractor is general-purpose.
"""

import re
import base64

# Minimal 1x1 transparent GIF placeholder (same as what Google uses)
PLACEHOLDER_GIF = "data:image/gif;base64,R0lGODlhAQABAIAAAP///////yH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="

# Tiny 1x1 JPEG (red pixel) to simulate an embedded base64 thumbnail
TINY_JPEG = (
    "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgK"
    "DBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBD"
    "AQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy"
    "MjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAABgUE/8QAIhAA"
    "AgIBBAMBAAAAAAAAAAAAAQIDBAUREiExQf/EABQBAQAAAAAAAAAAAAAAAAAAAAD/xAAUEQEAAAAA"
    "AAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AqWtardU9j3Da6xtFKNfG3yQpSAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAB/9k="
)


def build_item(name, year, href, img_id=None, left=8, width=153):
    """Build a single carousel item div."""
    img_id_attr = f' id="{img_id}"' if img_id else ""
    data_src_attr = (
        ""
        if img_id
        else f' data-src="https://encrypted-tbn0.gstatic.com/images?q=tbn:example_{name.replace(" ", "_")}"'
    )
    year_html = f'<div class="cxzHyb">{year}</div>' if year else '<div class="cxzHyb"></div>'

    return (
        f'<div class="iELo6" style="width:{width}px;top:8px;left:{left}px">'
        f'<a href="{href}">'
        f'<img class="taFZJe" alt="{name}"{img_id_attr}{data_src_attr} '
        f'src="{PLACEHOLDER_GIF}">'
        f'<div class="KHK6lb">'
        f'<div class="pgNMRc">{name}</div>'
        f'{year_html}'
        f"</div>"
        f"</a>"
        f"</div>"
    )


def build_image_script(img_id, base64_src):
    return (
        f"(function(){{var s='{base64_src}';"
        f"var ii=['{img_id}'];"
        f"var r='';_setImagesSrc(ii,s,r);}})();"
    )


def build_page(title, artist_name, artworks):
    """
    artworks: list of dicts with keys: name, year (or None), link_q
    First 3 get embedded thumbnails; the rest use data-src.
    """
    items_html = []
    scripts = []
    left = 8

    for i, art in enumerate(artworks):
        href = f"/search?q={art['link_q'].replace(' ', '+')}&hl=en&gl=us"
        img_id = None
        if i < 3:
            img_id = f"_test_{artist_name.replace(' ', '_')}_{i}"
            scripts.append(build_image_script(img_id, TINY_JPEG))

        items_html.append(build_item(art["name"], art.get("year"), href, img_id, left=left))
        left += 161

    items_joined = "\n".join(items_html)
    scripts_joined = "\n".join(f"<script>{s}</script>" for s in scripts)

    return f"""<!DOCTYPE html>
<html>
<head><title>{title}</title></head>
<body>
<div class="Cz5hV" style="height:485px">
{items_joined}
</div>
{scripts_joined}
</body>
</html>
"""


# ─── Claude Monet paintings ────────────────────────────────────────────────────

monet_artworks = [
    {"name": "Water Lilies", "year": "1906", "link_q": "Water Lilies Monet"},
    {"name": "Impression, Sunrise", "year": "1872", "link_q": "Impression Sunrise Monet"},
    {"name": "Haystacks", "year": "1890", "link_q": "Haystacks Monet"},
    {"name": "Rouen Cathedral", "year": "1894", "link_q": "Rouen Cathedral Monet"},
    {"name": "The Japanese Footbridge", "year": "1899", "link_q": "Japanese Footbridge Monet"},
    {"name": "Woman with a Parasol", "year": "1875", "link_q": "Woman with Parasol Monet"},
    {"name": "The Cliff Walk at Etretat", "year": "1882", "link_q": "Cliff Walk Etretat Monet"},
    {"name": "Poppy Field", "year": "1873", "link_q": "Poppy Field Monet"},
    {"name": "Boulevard des Capucines", "year": "1873", "link_q": "Boulevard des Capucines Monet"},
    {"name": "The Magpie", "year": "1869", "link_q": "The Magpie Monet"},
]

monet_html = build_page(
    "Claude Monet paintings - Google Search", "Claude Monet", monet_artworks
)

# ─── Rembrandt paintings ───────────────────────────────────────────────────────

rembrandt_artworks = [
    {"name": "The Night Watch", "year": "1642", "link_q": "The Night Watch Rembrandt"},
    {"name": "Self-Portrait with Two Circles", "year": "1665", "link_q": "Self Portrait Two Circles Rembrandt"},
    {"name": "The Anatomy Lesson of Dr. Nicolaes Tulp", "year": "1632", "link_q": "Anatomy Lesson Rembrandt"},
    {"name": "The Return of the Prodigal Son", "year": "1668", "link_q": "Prodigal Son Rembrandt"},
    {"name": "Bathsheba at Her Bath", "year": "1654", "link_q": "Bathsheba Rembrandt"},
    {"name": "The Syndics of the Drapers' Guild", "year": "1662", "link_q": "Syndics Drapers Guild Rembrandt"},
    {"name": "Belshazzar's Feast", "year": "1635", "link_q": "Belshazzar Feast Rembrandt"},
    {"name": "The Jewish Bride", "year": "1665", "link_q": "Jewish Bride Rembrandt"},
    {"name": "Portrait of Jan Six", "year": "1654", "link_q": "Portrait Jan Six Rembrandt"},
    {"name": "The Hundred Guilder Print", "year": None, "link_q": "Hundred Guilder Print Rembrandt"},
]

rembrandt_html = build_page(
    "Rembrandt paintings - Google Search", "Rembrandt", rembrandt_artworks
)

import os

files_dir = os.path.join(os.path.dirname(__file__))
with open(os.path.join(files_dir, "claude-monet-paintings.html"), "w") as f:
    f.write(monet_html)
print("Wrote claude-monet-paintings.html")

with open(os.path.join(files_dir, "rembrandt-paintings.html"), "w") as f:
    f.write(rembrandt_html)
print("Wrote rembrandt-paintings.html")
