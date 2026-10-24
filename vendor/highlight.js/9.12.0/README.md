# highlight.js 9.12.0 browser resources

2026-10-24 / FPR-111: these exact resources replace the former cdnjs 9.12.0
requests in `HtmlUtils.generateCodeHtml`. They remain version 9.12.0; this is
not a highlighter/theme upgrade. The common bundle registers 23 languages,
with the separate Go module making 24. Keep both existing GitHub (light) and
Atom One Dark (dark) styles and the existing configure/useBR/load initializer.

`provenance.json` pins immutable official commit URLs, byte sizes and SHA-256.
The original files are unmodified and match the formerly requested cdnjs
resources byte for byte. The full BSD-3-Clause notice comes from the source
repository's matching 9.12.0 release because the CDN release tree has no license
file. Keep `LICENSE` and its copyright/conditions/disclaimer when redistributing.
The generated HTML also embeds this complete notice for offline/binary use.

- [Official browser distribution](https://github.com/highlightjs/cdn-release/tree/d21e0a62084eb4b3a3b94d6dc45a10b3ed24906b/build)
- [Official 9.12.0 API](https://github.com/highlightjs/highlight.js/blob/16ab6f3b5f9a432e6e8825807103b6bb5cefef15/docs/api.rst)
- [Official license](https://github.com/highlightjs/highlight.js/blob/16ab6f3b5f9a432e6e8825807103b6bb5cefef15/LICENSE)

Regenerate with `python3 tool/generate_highlight_resources.py`; verify with
`python3 tool/generate_highlight_resources.py --check`. The tool only reads
these pinned local files and checks hashes; it never downloads resources.

The Dart data URI constants avoid platform file URL/read-access/baseUrl
differences and an actual `</script>` sequence inside the minified XML grammar.
Do not replace them with raw `<script>$javascript</script>` interpolation.
This removes network dependencies of the generated document's highlighter and
theme. Remote images/links supplied by source/release/comment content remain
content resources and retain their existing behavior.
