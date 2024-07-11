import csv
from collections import defaultdict

def main():
    db = open("blog.pl", "w")
    posts_file = open("posts.csv")
    tags_file = open("tags.csv")
    posts = csv.DictReader(posts_file)
    tags_csv = csv.DictReader(tags_file)
    tags = defaultdict(set)
    for tag in tags_csv:
        name = tag["name"]
        post_id = tag["post_id"]
        tags[post_id].add(name)

    for post in posts:
        slug = post["slug"]
        title = post["title"]
        date = post["date"]
        html = f"{slug}.html"
        post_id = post["id"]
        post_tags = "\",\"".join(list(tags[post_id]))
        with open(html, "w") as f:
            f.write(post["content"])
        db.write(f"post(\"{slug}\", \"{title}\", aarroyoc, \"{date}\", html(\"{html}\"), public, [\"{post_tags}\"]).\n")
    db.close()
    posts_file.close()
    tags_file.close()
            

if __name__ == "__main__":
    main()
