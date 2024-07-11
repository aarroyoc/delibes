:- use_module(library(lists)).
:- use_module(library(format)).
:- use_module(library(files)).
:- use_module(library(pio)).
:- use_module(library(dcgs)).
:- use_module(library(debug)).
:- use_module(library(time)).
:- use_module(library(lambda)).

:- use_module(teruel/teruel).

:- use_module(content/content).

:- initialization(main).

main :-
    portray_clause(delibes(version(1, 0, 0), author("Adrián Arroyo Calle"))),
    make_directory("output"),
    render_index,
    render_posts,
    render_tags,
    render_archive,
    copy_static,
    % Render RSS and sitemap
    halt.

render_posts :-
    findall(Slug, post(Slug, _, _, _, _, _, _), Slugs),
    maplist(render_post, Slugs).

render_post(Slug) :-
    post(Slug, Title, AuthorId, Date, html(ContentLocalPath), public, Tags),
    path_segments(ContentPath, ["content", ContentLocalPath]),
    phrase_from_file(seq(ContentHtml), ContentPath),
    phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
    phrase(format_time("%d/%m/%Y", T), DateStr),
    portray_clause(rendering_post(Slug)),
    render("templates/post.html", [
	       "title"-Title,
	       "content"-ContentHtml,
	       "date"-DateStr,
	       "tags"-Tags], Output),
    path_segments(PostPath, ["output", Slug]),
    make_directory(PostPath),
    path_segments(OutputPath, ["output", Slug, "index.html"]),
    phrase_to_file(seq(Output), OutputPath).

render_post(Slug) :-
    post(Slug, _, _, _, _, private, _).
    
render_tags :-
    path_segments(TagPath, ["output", "tag"]),
    make_directory(TagPath),
    findall(Tag, (
		post(_, _, _, _, _, public, Tags),
		member(Tag, Tags)), AllTags),
    sort(AllTags, Tags),
    maplist(render_tag, Tags).

render_tag(Tag) :-
    portray_clause(rendering_tag(Tag)),
    findall(Date-["slug"-Slug, "title"-Title, "date"-DateStr], (
		post(Slug, Title, _, Date, _, public, Tags),
		member(Tag, Tags),
		phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
		phrase(format_time("%d/%m/%Y", T), DateStr)		
	    ), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), SortedPosts, TagPosts),
    render("templates/archive.html", ["tag"-Tag, "posts"-TagPosts], Output),
    path_segments(TagPath, ["output", "tag", Tag]),
    make_directory(TagPath),
    path_segments(OutputPath, ["output", "tag", Tag, "index.html"]),
    phrase_to_file(seq(Output), OutputPath).
    

render_archive :-
    portray_clause(rendering_archive),
    findall(Date-["slug"-Slug, "title"-Title, "date"-DateStr], (
		post(Slug, Title, _, Date, _, public, _),
		phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
		phrase(format_time("%d/%m/%Y", T), DateStr)		
	    ), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), SortedPosts, ArchivePosts),
    render("templates/archive.html", ["tag"-"_", "posts"-ArchivePosts], Output),
    path_segments(ArchivePath, ["output", "archivo"]),
    make_directory(ArchivePath),
    path_segments(OutputPath, ["output", "archivo", "index.html"]),
    phrase_to_file(seq(Output), OutputPath).
    

render_index :-
    portray_clause(rendering_index),
    findall(Date-Slug,post(Slug, _, _, Date, _, public, _), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    length(IndexPosts, 5),
    append(IndexPosts, _, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), IndexPosts, IndexPostsSlugs),    
    maplist(post_index, IndexPostsSlugs, RenderPosts),
    render("templates/index.html", ["posts"-RenderPosts], Output),
    path_segments(Path, ["output", "index.html"]),
    phrase_to_file(seq(Output), Path).

post_index(Slug, ["slug"-Slug, "title"-Title, "date"-DateStr, "excerpt"-Excerpt]) :-
    post(Slug, Title, _, Date, html(ContentLocalPath), public, _),
    path_segments(ContentPath, ["content", ContentLocalPath]),
    phrase_from_file(excerpt(Excerpt), ContentPath),
    phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
    phrase(format_time("%d/%m/%Y", T), DateStr).    

excerpt(Excerpt) -->
    "<p>",
    seq(Excerpt),
    "</p>",
    ... .

copy_static :-
    path_segments(Path, ["output", "static"]),
    make_directory(Path),    
    directory_files("static", StaticFiles),
    maplist(copy_single_static, StaticFiles).

copy_single_static(StaticFile) :-
    portray_clause(copy_file(StaticFile)),
    path_segments(Origin, ["static", StaticFile]),
    path_segments(Destination, ["output", "static", StaticFile]),
    file_copy(Origin, Destination).
