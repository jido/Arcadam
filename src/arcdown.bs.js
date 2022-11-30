// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");
var $$Promise = require("@ryyppy/rescript-promise/src/Promise.bs.js");
var Belt_List = require("rescript/lib/js/belt_List.js");
var Js_string = require("rescript/lib/js/js_string.js");
var Belt_Array = require("rescript/lib/js/belt_Array.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");

var backtick = "`";

var source = "\nArcdown\nA lightweight markup language to format documents using plain text\n\nSyntax\nThe syntax of Arcdown is heavily inspired by AsciiDoc and by Markdown.\n\nHeaders\n= Document Title\n\n== Level 1 Section Title\n\n=== Level 2 Section Title...\nUse \"=\" in front of the header, repeated as needed to increase the level.\n\nThere must be only one document title in the document. The document title may be followed immediately by an optional document header which contains metadata related to the document, such as the authors or a marker for the generator to insert a table of contents.\n\nExample:\n\n= Document title\n:authors: Author Name <author@email.org>\n:version: v2.0, 2019-03-22\n:toc:\nParagraphs\nA sequence of non-empty lines form a paragraph.\n\nTo force a line break in the middle of a paragraph, end the line with \"+\".\n\nExample:\n\nThis is part of a single\nparagraph spread over\nmultiple lines of text. +\nBecause of the line break, this goes on a separate line.\nParagraphs may be grouped in a free block by enclosing them with \"--\".\n\nExample:\n\n--\nThis is the first paragraph.\n\nAnother paragraph is added\nto the block.\n--\nText Formatting\nThis is *bold*\n\nThis is _italic_\n\nThis is " + backtick + "monospaced" + backtick + "\n\nThis is ^superscript^\n\nThis is ~subscript~\n\nThis is #highlighted#\n\nThis is +_normal text_ (no style)+\nStyles can be combined. Any style can be used in the middle of a word by doubling the format markers, except for superscript and subscript which don't require doubling.\n\nExample:\n\n*_Combine bold and italic_*\n\nthe \"it\" is __it__alic\n\nsuperscri^pt^ for \"pt\"\nTo enter text which contains format markers, enclose the text with \"+\" to prevent the generator from interpreting them.\n\nBreaks\nHorizontal line:\n\n'''\nPage break (not visible in the browser if the output is a HTML document):\n\n<<<\nHyperlinks\n[Go to Products page on this site](/Products.html)\n\n[Go to Offers page in current path](Offers.html)\n\n[Go to an arbitrary webpage](https://www.github.com)\n\n[#anchor]:\nPart 1: This text is selected by the anchor.\n\n[Go to Part 1](#anchor)\nThe text inside square brackets becomes a hyperlink which loads the content specified in the round brackets. If the round brackets are empty and the text matches a section title then the link goes to that section.\n\nWhen the output format allows it, footnotes are also hyperlinks.\n\nExample:\n\nThere are contractual implications to this statement.[^terms]\n\n[^terms]:\nPlease refer to our [Terms and Conditions page](TandC.html) for more information.\nInline Content\n.sample image\n![Arcdown logo](Arcdown-logo.png)\n\nThe Github mascot: !![image](octocat.jpg)\nUse \"!\" in front of a hyperlink to insert an image or a multimedia file. Double the \"!\" to make the image in line with the text rather than in a new block.\n\nThe hyperlink text will be used as the \"alt\" label in HTML.\n\nCaptions are set using a Block Title.\n\nSee also Include.\n\nLists\n. Number one\n. Number two\n. Number three\n\n* First bullet\n* Second bullet\n* Third bullet\n\nItem 1:: First description\nItem 2:: Second description\nItem 3:: Third description\nA list that immediately follows an item from another list is automatically nested. Leading whitespace has no effect.\n\nOrdered and unordered list markers can be repeated to indicate the level, just like headers. Additional levels can be used in a description list by adding another \":\" each time.\n\nHowever these levels are not enforced so there could be a list level 1 (\*) nested inside a list level 2 (\*\*). It is good style to match the marker level with the nesting level of the list.\n\nExample:\n\n. This is number one\n** It has two bullets\n** This is the second bullet\n. This is number two\n  .. This is a sublist\n  .. with three elements\n  .. This is the third element\n[]\n. The empty attribute [] forces a\n  new list to start up\nUse \"+\" to force a list item on multiple lines. If it is used on an empty line, that starts a new paragraph. Note that indented code blocks don't require a \"+\".\n\nStyled Blocks\nCode blocks (monospaced):\n\n  Indented text without\n  line breaks is added\n  to a code block\n\n----\nAnother way to\ncreate a code\nblock using \"-\"\n----\n\n  ----\n  A delimited code block\n  can also be indented.\n\n  It allows empty lines\n  ----\nOther blocks:\n\n____\nQuote text using\nunderscores\n____\n\n====\nExample block used to\nenclose an example\n====\n\n****\nSidebar block used to\nexpand on a topic or\nhighlight an idea\n****\nTables\n|===\n| Header 1 \
| Header 2 \
| Header 3\n\n| Row 1 Column 1 | Row 1 Column 2\n| Row 1 Column 3\n\n| Row 2 Column 1\n2+| Row 2 Merged columns 2, 3\n|===\nAll the headers must be on the same line, or \"\\\" must be used to escape the line breaks otherwise the table is generated without a header row.\n\nAn empty line indicates a new row but it is optional after second row (since the generator knows the number of columns then, either from the header row or the first content row).\n\nOther table styles:\n\n,===\nHeader 1,Header 2,Header 3\n\nRow 1 Column 1,Row 1 Column 2,Row 1 Column 3\nRow 2 Column 1,Row 2 Column 2,Row 2 Column 3\n,===\n:===\nHeader 1:Header 2:Header 3\n\nRow 1 Column 1:Row 1 Column 2:Row 1 Column 3\nRow 2 Column 1:Row 2 Column 2:Row 2 Column 3\n:===\nBlock Title\n.Fruit basket\n,===\napples,oranges,pears\n,===\n\n.A mountain sunset on [Flickr](https://www.flickr.com/photos/javh/5448336655)\n[size=200x100]\n![Sunset](sunset.jpg)\nA block title starts with a dot \".\" on its own line. It comes before the attributes.\n\nIf the block title is used with an image, it is used as caption. Additionally, if the image caption contains a link then clicking on the image loads the (first) link.\n\nEscape character\nThe backslash \"\\\" is used to prevent the generator from interpreting the following character specially.\n\nExample:\n\n\* not a bullet list!\nSee also Text Formatting to prevent format markers from being interpreted over a span of text using \"+\".\n\nSubstitutions\n:substitution: value to be inserted\nOnce defined, substitution values can be reused anywhere.\n\nExample:\n\nUsing the {substitution}\n\n[{substitution}](/index.html)\nAttributes\nAn attribute is written inside square brackets and applies to the following paragraph or block.\n\nAdditional attributes can be applied using commas to separate them.\n\nExample:\n\n[source,xml]\n<root>\n  <element>\n    This is XML text which\n    can be colourized\n  </element>\n\n[NOTE]\n====\nThis is important.\n====\nIf the attribute starts with a dot \".\" and a stylesheet is defined, the specified style class is applied.\n\nSome attributes, such as the style class attribute, can be used in the middle of text by highlighting the part of the text they apply to.\n\nExample:\n\nThis paragraph contains [.underline]#underlined\ntext inside#.\nInclude\n[include]\n[region](Shared-file.arcd)\nUse the \"include\" attribute to substitute the hyperlink with the contents of an Arcdown file found at the specified location.\n\nThe hyperlink text may be used to provide a tag name so only the designated region of the Arcdown file is inserted instead of the whole contents.\n\nNote that for security reasons, including a file from an arbitrary location is disabled by default.\n\nTags\nThe begin and end tags define a named region for include:\n\n[:begin region]:\nThis text can be included\non its own\n\n[:end region]:\n\n----\nInside a code block, a named region is\n  //-- begin::coderegion ----\ndefined using begin:: and end:: tags after\nhyphens and before a code block marker\nthat ends the line.\n  //-- end::coderegion ----\n----\nCallouts\n[source,ruby]\n----\nrequire 'sinatra'\n# :1 ----\n\nget '/hi' do\n  # :2 ----\n  \"Hello World!\"\n  # :3 ----\nend\n----\n(1):: Library import\n(2):: URL mapping\n(3):: HTTP response body\nCallouts are inserted in the line above and the entire line which contains the callouts is deleted.\n\nIf the deleted line starts with a known block comment marker, the generator looks for a matched closing comment marker at the beginning of next line and deletes that too. (like /* */ in C or <!-- --> in XML)\n\nComments\n// Line comment\n\n////\nComment\nblock\n////\nComments are for information only.\n\nLocalisation\nArcdown documents can be localised for an international audience.\n\nDefine the \"translations\" substitution to enable it:\n\n:translations: cn en es fr jp kr ru\nThis tells the generator to look for translations in the listed directories.\n\nLocalisation files contain the text to translate with synchronisation marks @ which serve as placeholders for untranslatable text. These marks always appear at the start of a line.\n\nThe following are included in the translation:\n\nformatting\nin-line attributes\nhyperlinks and inline content\nlabels (footnotes and anchors)\ncallouts\nuser-defined substitutions\ncomments\nBy default, code blocks are excluded. To include a code block use the \"localize\" attribute:\n\n[localize=Y]\n----\nThis will be translated.\n----\nSimilarly, the same attribute can be used to prevent the translation of text:\n\n[localize=N]\nThis must not be translated.\nIf applied to an include, it prevents the generator from looking for a matching localisation file. Instead, the include link is added to the translation so that it can be customised for each locale.\n";

var lines = Js_string.split("\n", source);

var EndOfFile = /* @__PURE__ */Caml_exceptions.create("Arcdown.EndOfFile");

function nextLine(lnum) {
  var line = Belt_Array.get(lines, lnum);
  if (line !== undefined) {
    return Promise.resolve([
                line,
                lnum + 1 | 0
              ]);
  } else {
    return Promise.reject({
                RE_EXN_ID: EndOfFile,
                _1: "EOF"
              });
  }
}

var alpha = "A-Za-z";

var alnum = "0-9" + alpha;

function getMatches(regex, someline) {
  var result = regex.exec(someline);
  if (result !== null) {
    return Belt_Array.map(result, (function (x) {
                  return Belt_Option.getWithDefault((x == null) ? undefined : Caml_option.some(x), "");
                }));
  } else {
    return [];
  }
}

function consumeTitle(line, subs) {
  var titleLine = /^=+\s+([^\s].*)/;
  var match = getMatches(titleLine, line);
  if (match.length !== 2) {
    return [
            false,
            subs
          ];
  }
  var title = match[1];
  console.log("TITLE: " + title);
  return [
          true,
          subs
        ];
}

function consumeSubstitution(line, lnum, subs) {
  var pattern = "^:([" + alpha + "]+(\\.[_" + alnum + "]+)*):\\s*(.*)";
  var substLine = new RegExp(pattern);
  var match = getMatches(substLine, line);
  if (match.length !== 4) {
    return [
            false,
            lnum,
            subs
          ];
  }
  var name = match[1];
  var value = match[3];
  console.log("SUBST: " + name + " --> " + value);
  return [
          true,
          lnum,
          Belt_List.add(subs, [
                name,
                value
              ])
        ];
}

function consumeAttribute(line, subs) {
  var attrLine = /^\[\s*([^\[\]]*)\]\s*$/;
  var match = getMatches(attrLine, line);
  if (match.length !== 2) {
    return [
            false,
            subs,
            ""
          ];
  }
  var attributes = match[1];
  return [
          true,
          subs,
          attributes
        ];
}

function consumeNormalLine(line, param, param$1) {
  console.log("TEXT: " + line);
}

var EndOfBlock = /* @__PURE__ */Caml_exceptions.create("Arcdown.EndOfBlock");

function consumeExampleBlock(line, lnum, subs, attrs) {
  var blockLine = /^====\s*$/;
  var match = getMatches(blockLine, line);
  if (match.length !== 1) {
    return Promise.resolve([
                lnum,
                subs,
                attrs
              ]);
  }
  console.log("BLOCK: Example with attributes: " + attrs);
  var checkEndBlock = function (ln) {
    return getMatches(blockLine, ln).length !== 0;
  };
  var promi = function (param) {
    var attrs = param[2];
    var subs = param[1];
    var lnum = param[0];
    return $$Promise.$$catch(consumeLine(lnum, subs, attrs, "=", checkEndBlock).then(promi), (function (err) {
                  if (err.RE_EXN_ID === EndOfBlock) {
                    console.log("BLOCK: Example ended at line " + String(lnum));
                    return Promise.resolve([
                                lnum + 1 | 0,
                                subs,
                                attrs
                              ]);
                  } else if (err.RE_EXN_ID === EndOfFile) {
                    console.log("WARNING: Example block not closed");
                    return Promise.reject(err);
                  } else {
                    console.log("WARNING: Unexpected error");
                    return Promise.reject(err);
                  }
                }));
  };
  return promi([
              lnum,
              subs,
              attrs
            ]);
}

function consumeLine(lnum, subs, attrs, endchar, confirm) {
  var firstChar = /^./;
  return nextLine(lnum).then(function (param) {
              var lnum = param[1];
              var line = param[0];
              var m = getMatches(firstChar, line);
              var len = m.length;
              if (len !== 1) {
                if (len !== 0) {
                  console.log("Unexpected! " + String(m.length));
                  return Promise.resolve([
                              lnum,
                              subs,
                              ""
                            ]);
                } else {
                  console.log("<empty>");
                  return Promise.resolve([
                              lnum,
                              subs,
                              attrs
                            ]);
                }
              }
              var chara = m[0];
              if (endchar === chara && Curry._1(confirm, line)) {
                return Promise.reject({
                            RE_EXN_ID: EndOfBlock,
                            _1: "example"
                          });
              }
              switch (chara) {
                case ":" :
                    console.log("Maybe a substitution");
                    var match = consumeSubstitution(line, lnum, subs);
                    if (match[0]) {
                      return Promise.resolve([
                                  match[1],
                                  match[2],
                                  ""
                                ]);
                    } else {
                      consumeNormalLine(line, subs, attrs);
                      return Promise.resolve([
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    }
                case "=" :
                    console.log("Maybe a title");
                    var match$1 = consumeTitle(line, subs);
                    if (match$1[0]) {
                      return Promise.resolve([
                                  lnum,
                                  match$1[1],
                                  ""
                                ]);
                    } else {
                      return consumeExampleBlock(line, lnum, subs, attrs).then(function (param) {
                                  var subs = param[1];
                                  var next = param[0];
                                  if (next > lnum) {
                                    return Promise.resolve([
                                                next,
                                                subs,
                                                ""
                                              ]);
                                  } else {
                                    consumeNormalLine(line, subs, param[2]);
                                    return Promise.resolve([
                                                lnum,
                                                subs,
                                                ""
                                              ]);
                                  }
                                });
                    }
                case "[" :
                    console.log("Maybe an attribute");
                    var match$2 = consumeAttribute(line, subs);
                    var attributes = match$2[2];
                    if (match$2[0]) {
                      console.log("ATTR: " + attributes);
                      return Promise.resolve([
                                  lnum,
                                  match$2[1],
                                  attributes
                                ]);
                    } else {
                      consumeNormalLine(line, subs, attrs);
                      return Promise.resolve([
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    }
                default:
                  console.log("Something else");
                  return Promise.resolve([
                              lnum,
                              subs,
                              ""
                            ]);
              }
            });
}

var attrs = "";

function promi(param) {
  return $$Promise.$$catch(consumeLine(param[0], param[1], param[2], "$", (function (param) {
                      return false;
                    })), (function (err) {
                  if (err.RE_EXN_ID === EndOfFile) {
                    console.log("DONE");
                    return Promise.reject(err);
                  } else {
                    console.log("Unexpected error");
                    return Promise.reject(err);
                  }
                })).then(promi);
}

promi([
      0,
      /* [] */0,
      attrs
    ]);

var subs = /* [] */0;

var lnum = 0;

exports.backtick = backtick;
exports.source = source;
exports.lines = lines;
exports.EndOfFile = EndOfFile;
exports.nextLine = nextLine;
exports.alpha = alpha;
exports.alnum = alnum;
exports.getMatches = getMatches;
exports.consumeTitle = consumeTitle;
exports.consumeSubstitution = consumeSubstitution;
exports.consumeAttribute = consumeAttribute;
exports.consumeNormalLine = consumeNormalLine;
exports.EndOfBlock = EndOfBlock;
exports.consumeExampleBlock = consumeExampleBlock;
exports.consumeLine = consumeLine;
exports.subs = subs;
exports.attrs = attrs;
exports.lnum = lnum;
exports.promi = promi;
/* lines Not a pure module */
