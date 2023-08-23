// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

class Wiki {
  Wiki(this.root);

  final String root;

  final Map<String, WikiPage> _pages = <String, WikiPage>{};

  Set<WikiPage> get pages => _pages.values.toSet();

  WikiPage pageForFilename(final String filename) {
    return _pages.putIfAbsent(Uri.decodeFull(filename).toLowerCase(), () => WikiPage(filename));
  }

  WikiPage? pageForUrl(final String url) {
    if (url.startsWith(root)) {
      int end = url.indexOf('#');
      if (end < 0) {
        end = url.length;
      }
      return pageForFilename('${url.substring(root.length, end)}.md');
    }
    return null;
  }

  WikiPage pageForTitle(final String title) {
    final String filename = '${title.replaceAll(' ', '-')}.md';
    return pageForFilename(filename);
  }
}

class WikiPage {
  WikiPage(this.filename);

  final String filename;

  final Set<WikiPage> sources = <WikiPage>{}; // pages pointing to us
  final Set<WikiPage> targets = <WikiPage>{}; // pages we point to

  bool parsed = false;

  String get title {
    assert(filename.endsWith('.md'), 'not sure how to handle non-markdown files');
    return Uri.decodeFull(filename.substring(0, filename.length - 3)).replaceAll('-', ' ');
  }

  void parse(final Wiki wiki) {
    parseFromString(wiki, File(filename).readAsStringSync());
  }

  void parseFromString(final Wiki wiki, final String body) {
    assert(!parsed, 'cannot parse a wiki page twice');
    _parseTokens(wiki, _tokenize(body.runes));
  }

  void _parseTokens(final Wiki wiki, final List<_Token> tokens) {
    final Set<String> footnoteLinks = <String>{};
    final Map<String, String> footnoteDefinitions = <String, String>{};
    for (final _Token token in tokens) {
      switch (token) {
        case _TextToken():
          break;
        case _InternalLinkToken(options: final List<String> options):
          if (options.any(
            (final String option) =>
                option.startsWith('width=') || option.startsWith('height=') || option.startsWith('alt='),
          )) {
            // it's an image; ignore it.
          } else {
            String title = options.last;
            if (title.contains('#')) {
              title = title.substring(0, title.indexOf('#'));
            }
            if (title.isNotEmpty) {
              final WikiPage page = wiki.pageForTitle(title);
              if (page != this) {
                targets.add(page);
                page.sources.add(this);
              }
            }
          }
        case _HyperlinkToken(url: final String url):
          final WikiPage? page = wiki.pageForUrl(url);
          if (page != null && page != this) {
            targets.add(page);
            page.sources.add(this);
          }
        case _FootnoteLinkToken(footnote: final String footnote):
          footnoteLinks.add(_cleanFootnote(footnote));
        case _FootnoteDefinitionToken(label: final String label, url: final String url):
          if (footnoteDefinitions.containsKey(label)) {
            stderr.writeln('$filename: duplicate footnote "$label"');
          }
          footnoteDefinitions[_cleanFootnote(label)] = url;
        case _ErrorToken(message: final String message, line: final int line, column: final int column):
          stderr.writeln('$filename:$line:$column: $message');
      }
    }
    for (final String footnote in footnoteLinks) {
      if (footnoteDefinitions.containsKey(footnote)) {
        final WikiPage? page = wiki.pageForUrl(footnoteDefinitions[footnote]!);
        if (page != null && page != this) {
          targets.add(page);
          page.sources.add(this);
        }
      }
    }
    parsed = true;
  }

  final RegExp whitespace = RegExp(r'[ \n]+');

  String _cleanFootnote(final String label) {
    return label.replaceAll(whitespace, ' ');
  }

  Set<WikiPage> findAllAccessible() {
    final Set<WikiPage> result = <WikiPage>{};
    final Set<WikiPage> stack = <WikiPage>{this};
    while (stack.isNotEmpty) {
      final WikiPage current = stack.first;
      stack.remove(current);
      if (result.contains(current)) {
        continue;
      }
      result.add(current);
      stack.addAll(current.targets);
    }
    return result;
  }
}

final class _Token {}

final class _TextToken extends _Token {
  _TextToken(this.text);
  final String text;
}

final class _InternalLinkToken extends _Token {
  _InternalLinkToken(this.label, this.options);
  final String label;
  final List<String> options;
}

final class _HyperlinkToken extends _Token {
  _HyperlinkToken(this.label, this.url);
  final String label;
  final String url;
}

final class _FootnoteLinkToken extends _Token {
  _FootnoteLinkToken(this.label, this.footnote);
  final String label;
  final String footnote;
}

final class _FootnoteDefinitionToken extends _Token {
  _FootnoteDefinitionToken(this.label, this.url);
  final String label;
  final String url;
}

final class _ErrorToken extends _Token {
  _ErrorToken(this.message, this.line, this.column);
  final String message;
  final int line;
  final int column;
}

enum _Mode {
  normal,
  linkStart,
  internalLinkText,
  internalLinkTextEnd,
  internalLinkPage,
  internalLinkPageEnd,
  hyperlinkText,
  linkHyperlinkSeparators,
  hyperlinkUrl,
  footnoteLabel,
  footnoteUrl,
  backtick1,
  backtick2,
  codeLine,
  codeBlock,
  codeBlockBacktick1,
  codeBlockBacktick2,
  eof,
}

List<_Token> _tokenize(final Iterable<int> input) {
  final List<_Token> results = <_Token>[];
  _Mode mode = _Mode.normal;
  final List<int> buffer = <int>[];
  final List<int> spaceBuffer = <int>[];
  final List<int> linkBuffer = <int>[];
  int line = 1;
  int column = 1;
  void flushBuffer() {
    if (buffer.isNotEmpty) {
      results.add(_TextToken(String.fromCharCodes(buffer)));
      buffer.clear();
    }
  }

  void error(final String message) {
    results.add(_ErrorToken(message, line, column));
  }

  void process(final int character) {
    if (character == 0x0A) {
      line += 1;
      column = 0;
    }
    column += 1;
    retokenize:
    while (true) {
      switch (mode) {
        case _Mode.normal:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x5B: // U+005B LEFT SQUARE BRACKET character ([)
              flushBuffer();
              mode = _Mode.linkStart;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              mode = _Mode.backtick1;
              return;
            default:
              buffer.add(character);
              return;
          }

        case _Mode.linkStart:
          switch (character) {
            case -1: // EOF
              error('unexpected EOF in link');
              buffer.insert(0, 0x5B);
              mode = _Mode.eof;
              return;
            case 0x5B: // U+005B LEFT SQUARE BRACKET character ([)
              mode = _Mode.internalLinkText;
              return;
            default:
              mode = _Mode.hyperlinkText;
              continue retokenize;
          }

        case _Mode.internalLinkText:
          switch (character) {
            case -1: // EOF
              error('unexpected EOF in internal link');
              buffer.insert(0, 0x5B);
              buffer.insert(0, 0x5B);
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              mode = _Mode.internalLinkTextEnd;
              return;
            case 0x7C: // U+007C VERTICAL LINE character (|)
              mode = _Mode.internalLinkPage;
              assert(linkBuffer.isEmpty, 'internal violation');
              return;
            default:
              buffer.add(character);
              return;
          }

        case _Mode.internalLinkTextEnd:
          switch (character) {
            case -1: // EOF
              error('unexpected EOF after internal link');
              buffer.insert(0, 0x5B);
              buffer.insert(0, 0x5B);
              buffer.add(0x5D);
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              mode = _Mode.normal;
              results.add(_InternalLinkToken(String.fromCharCodes(buffer), <String>[String.fromCharCodes(buffer)]));
              buffer.clear();
              return;
            default:
              buffer.insert(0, 0x5B);
              buffer.insert(0, 0x5B);
              buffer.add(0x7C);
              mode = _Mode.hyperlinkText;
              continue retokenize;
          }

        case _Mode.internalLinkPage:
          switch (character) {
            case -1: // EOF
              error('unexpected EOF in internal link page name');
              buffer.insert(0, 0x5B);
              buffer.insert(0, 0x5B);
              buffer.add(0x7C);
              buffer.addAll(linkBuffer);
              linkBuffer.clear();
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              mode = _Mode.internalLinkPageEnd;
              return;
            default:
              linkBuffer.add(character);
              return;
          }

        case _Mode.internalLinkPageEnd:
          switch (character) {
            case -1: // EOF
              error('unexpected EOF after internal link');
              buffer.insert(0, 0x5B);
              buffer.insert(0, 0x5B);
              buffer.add(0x7C);
              buffer.addAll(linkBuffer);
              buffer.add(0x5D);
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              results.add(
                _InternalLinkToken(
                  String.fromCharCodes(buffer),
                  String.fromCharCodes(linkBuffer).split('|').toList(),
                ),
              );
              buffer.clear();
              linkBuffer.clear();
              mode = _Mode.normal;
              return;
            default:
              linkBuffer.add(0x5D);
              linkBuffer.add(character);
              return;
          }

        case _Mode.hyperlinkText:
          switch (character) {
            case -1: // EOF
              buffer.insert(0, 0x5B);
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              mode = _Mode.linkHyperlinkSeparators;
              assert(spaceBuffer.isEmpty, 'internal violation');
              return;
            default:
              buffer.add(character);
              return;
          }

        case _Mode.linkHyperlinkSeparators:
          switch (character) {
            case -1: // EOF
              buffer.insert(0, 0x5B);
              buffer.add(0x5D);
              buffer.addAll(spaceBuffer);
              mode = _Mode.eof;
              return;
            case 0x0A:
            case 0x20:
              spaceBuffer.add(character);
              return;
            case 0x28: // U+0028 LEFT PARENTHESIS character (()
              mode = _Mode.hyperlinkUrl;
              assert(linkBuffer.isEmpty, 'internal violation');
              return;
            case 0x3A: // U+003A COLON character (:)
              mode = _Mode.footnoteUrl;
              assert(linkBuffer.isEmpty, 'internal violation');
              return;
            case 0x5B: // U+005B LEFT SQUARE BRACKET character ([)
              mode = _Mode.footnoteLabel;
              assert(linkBuffer.isEmpty, 'internal violation');
              return;
            default:
              buffer.insert(0, 0x5B);
              buffer.add(0x5D);
              buffer.addAll(spaceBuffer);
              spaceBuffer.clear();
              mode = _Mode.normal;
              continue retokenize;
          }

        case _Mode.hyperlinkUrl:
          switch (character) {
            case -1: // EOF
              buffer.insert(0, 0x5B);
              buffer.add(0x5D);
              buffer.addAll(spaceBuffer);
              buffer.add(0x28);
              buffer.addAll(linkBuffer);
              mode = _Mode.eof;
              return;
            case 0x29: // U+0029 RIGHT PARENTHESIS character ())
              results.add(_HyperlinkToken(String.fromCharCodes(buffer), String.fromCharCodes(linkBuffer)));
              buffer.clear();
              spaceBuffer.clear();
              linkBuffer.clear();
              mode = _Mode.normal;
              return;
            default:
              linkBuffer.add(character);
              return;
          }

        case _Mode.footnoteUrl:
          switch (character) {
            case -1: // EOF
            case 0x0A: // newline
              results
                  .add(_FootnoteDefinitionToken(String.fromCharCodes(buffer), String.fromCharCodes(linkBuffer).trim()));
              buffer.clear();
              spaceBuffer.clear();
              linkBuffer.clear();
              mode = _Mode.normal;
              continue retokenize;
            default:
              linkBuffer.add(character);
              return;
          }

        case _Mode.footnoteLabel:
          switch (character) {
            case -1: // EOF
              buffer.insert(0, 0x5B);
              buffer.add(0x5D);
              buffer.addAll(spaceBuffer);
              buffer.add(0x5B);
              buffer.addAll(linkBuffer);
              mode = _Mode.eof;
              return;
            case 0x5D: // U+005D RIGHT SQUARE BRACKET character (])
              if (linkBuffer.isEmpty) {
                results.add(_FootnoteLinkToken(String.fromCharCodes(buffer), String.fromCharCodes(buffer)));
              } else {
                results.add(_FootnoteLinkToken(String.fromCharCodes(buffer), String.fromCharCodes(linkBuffer)));
              }
              buffer.clear();
              spaceBuffer.clear();
              linkBuffer.clear();
              mode = _Mode.normal;
              return;
            default:
              linkBuffer.add(character);
              return;
          }

        case _Mode.backtick1:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.backtick2;
              return;
            default:
              buffer.add(character);
              mode = _Mode.codeLine;
              return;
          }

        case _Mode.backtick2:
          switch (character) {
            case -1: // EOF
              buffer.add(character);
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.codeBlock;
              return;
            default:
              mode = _Mode.normal;
              continue retokenize;
          }

        case _Mode.codeBlock:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.codeBlockBacktick1;
              return;
            default:
              buffer.add(character);
              return;
          }

        case _Mode.codeLine:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.normal;
              return;
            default:
              buffer.add(character);
              return;
          }

        case _Mode.codeBlockBacktick1:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.codeBlockBacktick2;
              return;
            default:
              buffer.add(character);
              mode = _Mode.codeBlock;
              return;
          }

        case _Mode.codeBlockBacktick2:
          switch (character) {
            case -1: // EOF
              mode = _Mode.eof;
              return;
            case 0x60: // U+0060 GRAVE ACCENT character (`)
              buffer.add(character);
              mode = _Mode.normal;
              return;
            default:
              buffer.add(character);
              mode = _Mode.codeBlock;
              return;
          }

        case _Mode.eof:
          assert(false, 'internal violation');
      }
    }
  }

  input.forEach(process);
  assert(mode != _Mode.eof, 'internal violation');
  process(-1);
  assert(mode == _Mode.eof, 'internal violation');
  flushBuffer();
  return results;
}
