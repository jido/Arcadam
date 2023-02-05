// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var $$Promise = require("@ryyppy/rescript-promise/src/Promise.bs.js");
var Caml_obj = require("rescript/lib/js/caml_obj.js");
var Belt_List = require("rescript/lib/js/belt_List.js");
var Js_string = require("rescript/lib/js/js_string.js");
var Belt_Array = require("rescript/lib/js/belt_Array.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");

var spaces = "      ";

var source = "\n[NOTE]\n====\nThis is how to start a new example\nblock within this block:\n" + spaces + "\n.Nested block<\n[example]\n====\nA small example\n====\n====\n\n:subs: value&more\n== Arcdown Test ->> part 1\n\n[Go to Products page on this site](/Products.html)\n\n[Go to Offers page in current path](Offers.html)\n\n[Go to an arbitrary webpage](https://www.github.com)\n\n[#anchor]:\nPart 1: This text is selected by the anchor.\n\n[<Go to Part 1>](#anchor)\n\n____\nQuote text using\nunderscores\n____\n\n====\nExample block used to\nenclose an example\n====\n\n****\nSidebar block used to\nexpand on a topic or\nhighlight an idea\n****\n\n* First<\nmulti line\n* Second&&\n** sublist\n** one more\n... nested numbered list\n... nested 2\n* Third\n[list]\n. Number one\n";

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

var EndOfFile = /* @__PURE__ */Caml_exceptions.create("Arcdown.EndOfFile");

var lines = Js_string.split("\n", source);

function nextLine(lnum) {
  var line = Belt_Array.get(lines, lnum);
  if (line === undefined) {
    return Promise.reject({
                RE_EXN_ID: EndOfFile,
                _1: "EOF"
              });
  }
  var trimEnd = /^((\s*[^\s]+)*)\s*$/;
  var match = getMatches(trimEnd, line);
  if (match.length !== 3) {
    return Promise.resolve([
                "",
                lnum + 1 | 0
              ]);
  }
  var line$1 = match[1];
  return Promise.resolve([
              line$1,
              lnum + 1 | 0
            ]);
}

function specialCharsStep(text) {
  var result = Js_string.replaceByRe(/&/g, "&amp;", text);
  var result$1 = Js_string.replaceByRe(/</g, "&lt;", result);
  return Js_string.replaceByRe(/>/g, "&gt;", result$1);
}

function consumeBlockTitle(line) {
  var blockTitleLine = /^\.([^\s].*)$/;
  var match = getMatches(blockTitleLine, line);
  if (match.length !== 2) {
    return [];
  }
  var title = match[1];
  console.log("BLOCKTITLE: " + title);
  return [
          /* BlockTitle */5,
          {
            TAG: /* Text */0,
            _0: title
          }
        ];
}

function consumeHeading(line) {
  var titleLine = /^(=+)\s+([^\s].*)$/;
  var match = getMatches(titleLine, line);
  if (match.length !== 3) {
    return [];
  }
  var signs = match[1];
  var title = match[2];
  var level = signs.length;
  console.log("HEADING(level " + String(level) + "): " + title);
  return [
          {
            TAG: /* Heading */1,
            _0: level
          },
          {
            TAG: /* Text */0,
            _0: title
          }
        ];
}

function consumeSubstitution(line) {
  var pattern = "^:([" + alpha + "][_" + alnum + "]*(\\.[_" + alnum + "]+)*):\\s+(.*)\$";
  var substLine = new RegExp(pattern);
  var match = getMatches(substLine, line);
  if (match.length !== 4) {
    return [];
  }
  var name = match[1];
  var value = match[3];
  console.log("SUBST: " + name + " --> " + value + "");
  return [
          {
            TAG: /* SubstitutionDef */6,
            _0: name
          },
          {
            TAG: /* Text */0,
            _0: value
          }
        ];
}

function consumeAttribute(line) {
  var attrLine = /^\[\s*([^\[\]]*)\]$/;
  var match = getMatches(attrLine, line);
  if (match.length !== 2) {
    return [];
  }
  var attributes = match[1];
  console.log("ATTR: " + attributes);
  return [{
            TAG: /* Attribute */2,
            _0: attributes
          }];
}

function consumeHyperlink(line) {
  var hlinkLine = /\[\s*([^\]]*)\]\(\s*([^\s\)]*)\s*\)/;
  var match = getMatches(hlinkLine, line);
  if (match.length !== 3) {
    return [];
  }
  var text = match[1];
  var link = match[2];
  console.log("LINK: <" + link + "> with text: '" + text + "'");
  return [
          {
            TAG: /* Hyperlink */7,
            _0: link
          },
          {
            TAG: /* Text */0,
            _0: text
          }
        ];
}

function consumeLabel(line) {
  var labelLine = /^\[\s*([^\]]+)\]:\s*$/;
  var match = getMatches(labelLine, line);
  if (match.length !== 2) {
    return [];
  }
  var label = match[1];
  console.log("LABEL: " + label + "");
  return [{
            TAG: /* Label */5,
            _0: label
          }];
}

function consumeBulletListItem(line) {
  var itemLine = /^\s*([*]+)\s+(.*)$/;
  var match = getMatches(itemLine, line);
  if (match.length !== 3) {
    return [];
  }
  var stars = match[1];
  var text = match[2];
  var level = stars.length;
  console.log("LIST: bullet level " + String(level) + " with text: '" + text + "'");
  return [
          {
            TAG: /* BulletListItem */3,
            _0: level
          },
          {
            TAG: /* Text */0,
            _0: text
          }
        ];
}

function consumeNumberedListItem(line) {
  var itemLine = /^\s*([.]+)\s+(.*)$/;
  var match = getMatches(itemLine, line);
  if (match.length !== 3) {
    return [];
  }
  var dots = match[1];
  var text = match[2];
  var level = dots.length;
  console.log("LIST: item level " + String(level) + " with text: '" + text + "'");
  return [
          {
            TAG: /* NumberedListItem */4,
            _0: level
          },
          {
            TAG: /* Text */0,
            _0: text
          }
        ];
}

function consumeRegularLine(line) {
  var chara = Js_string.charAt(0, line);
  var tok;
  switch (chara) {
    case "*" :
        tok = consumeBulletListItem(line);
        break;
    case "." :
        tok = consumeNumberedListItem(line);
        break;
    case "[" :
        tok = consumeHyperlink(line);
        break;
    default:
      tok = [];
  }
  if (Caml_obj.equal(tok, [])) {
    console.log("TEXT: " + line);
    return [{
              TAG: /* Text */0,
              _0: line
            }];
  } else {
    return tok;
  }
}

var EndOfBlock = /* @__PURE__ */Caml_exceptions.create("Arcdown.EndOfBlock");

function consumeRegularBlock(name, delimiter, line, lnum, subs, attrs) {
  if (line !== delimiter) {
    return Promise.resolve([
                lnum,
                subs,
                attrs
              ]);
  }
  console.log("BLOCK: " + name + " with attributes [" + attrs + "]");
  var promi = function (param) {
    var attrs = param[3];
    var subs = param[2];
    var lnum = param[1];
    return $$Promise.$$catch((
                  param[0] ? consumeInitialLine(lnum, subs, attrs, delimiter) : consumeLine(lnum, subs, attrs, delimiter)
                ).then(promi), (function (err) {
                  if (err.RE_EXN_ID === EndOfBlock) {
                    console.log("BLOCK: " + name + " ended at line " + String(lnum) + "");
                    return Promise.resolve([
                                lnum + 1 | 0,
                                subs,
                                attrs
                              ]);
                  } else if (err.RE_EXN_ID === EndOfFile) {
                    console.log("WARNING: " + name + " block not closed");
                    return Promise.reject(err);
                  } else {
                    console.log("WARNING: Unexpected error");
                    return Promise.reject(err);
                  }
                }));
  };
  return promi([
              true,
              lnum,
              subs,
              attrs
            ]);
}

function consumeInitialLine(lnum, subs, attrs, delimiter) {
  return nextLine(lnum).then(function (param) {
              var lnum = param[1];
              var line = param[0];
              if (line === "") {
                return Promise.resolve([
                            true,
                            lnum,
                            subs,
                            attrs
                          ]);
              }
              if (attrs === "" && line === delimiter) {
                return Promise.reject({
                            RE_EXN_ID: EndOfBlock,
                            _1: delimiter
                          });
              }
              var chara = Js_string.charAt(0, line);
              switch (chara) {
                case "*" :
                    return consumeRegularBlock("Sidebar", "****", line, lnum, subs, attrs).then(function (param) {
                                var next = param[0];
                                if (next === lnum) {
                                  consumeRegularLine(line);
                                }
                                return Promise.resolve([
                                            next !== lnum,
                                            next,
                                            param[1],
                                            ""
                                          ]);
                              });
                case "." :
                    var consumed = consumeBlockTitle(line);
                    if (Caml_obj.notequal(consumed, [])) {
                      return Promise.resolve([
                                  true,
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    } else {
                      consumeRegularLine(line);
                      return Promise.resolve([
                                  false,
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    }
                case ":" :
                    var consumed$1 = consumeSubstitution(line);
                    if (consumed$1.length === 2) {
                      var name = consumed$1[0];
                      if (typeof name !== "number" && name.TAG === /* SubstitutionDef */6) {
                        var value = consumed$1[1];
                        if (typeof value !== "number" && value.TAG === /* Text */0) {
                          var subs$1 = Belt_List.add(subs, [
                                name._0,
                                value._0
                              ]);
                          return Promise.resolve([
                                      true,
                                      lnum,
                                      subs$1,
                                      ""
                                    ]);
                        }
                        
                      }
                      
                    }
                    if (!Caml_obj.equal(consumed$1, [])) {
                      throw {
                            RE_EXN_ID: "Assert_failure",
                            _1: [
                              "arcdown.res",
                              292,
                              10
                            ],
                            Error: new Error()
                          };
                    }
                    consumeRegularLine(line);
                    return Promise.resolve([
                                false,
                                lnum,
                                subs,
                                ""
                              ]);
                case "=" :
                    var consumed$2 = consumeHeading(line);
                    if (Caml_obj.notequal(consumed$2, [])) {
                      return Promise.resolve([
                                  true,
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    } else {
                      return consumeRegularBlock("Example", "====", line, lnum, subs, attrs).then(function (param) {
                                  var next = param[0];
                                  if (next === lnum) {
                                    consumeRegularLine(line);
                                  }
                                  return Promise.resolve([
                                              next !== lnum,
                                              next,
                                              param[1],
                                              ""
                                            ]);
                                });
                    }
                case "[" :
                    var consumed$3 = consumeAttribute(line);
                    if (consumed$3.length === 1) {
                      var attributes = consumed$3[0];
                      if (typeof attributes !== "number" && attributes.TAG === /* Attribute */2) {
                        return Promise.resolve([
                                    true,
                                    lnum,
                                    subs,
                                    attributes._0
                                  ]);
                      }
                      
                    }
                    if (!Caml_obj.equal(consumed$3, [])) {
                      throw {
                            RE_EXN_ID: "Assert_failure",
                            _1: [
                              "arcdown.res",
                              301,
                              10
                            ],
                            Error: new Error()
                          };
                    }
                    var consumed$4 = consumeLabel(line);
                    if (Caml_obj.notequal(consumed$4, [])) {
                      return Promise.resolve([
                                  true,
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    } else {
                      consumeRegularLine(line);
                      return Promise.resolve([
                                  false,
                                  lnum,
                                  subs,
                                  ""
                                ]);
                    }
                case "_" :
                    return consumeRegularBlock("Quote", "____", line, lnum, subs, attrs).then(function (param) {
                                var next = param[0];
                                if (next === lnum) {
                                  consumeRegularLine(line);
                                }
                                return Promise.resolve([
                                            next !== lnum,
                                            next,
                                            param[1],
                                            ""
                                          ]);
                              });
                default:
                  consumeRegularLine(line);
                  return Promise.resolve([
                              false,
                              lnum,
                              subs,
                              ""
                            ]);
              }
            });
}

function consumeLine(lnum, subs, attrs, delimiter) {
  return nextLine(lnum).then(function (param) {
              var lnum = param[1];
              var line = param[0];
              if (line === "") {
                console.log("<empty>");
                return Promise.resolve([
                            true,
                            lnum,
                            subs,
                            attrs
                          ]);
              }
              if (attrs === "" && line === delimiter) {
                return Promise.reject({
                            RE_EXN_ID: EndOfBlock,
                            _1: delimiter
                          });
              }
              var chara = Js_string.charAt(0, line);
              if (chara === "[") {
                var consumed = consumeAttribute(line);
                if (consumed.length === 1) {
                  var attributes = consumed[0];
                  if (typeof attributes !== "number" && attributes.TAG === /* Attribute */2) {
                    return Promise.resolve([
                                true,
                                lnum,
                                subs,
                                attributes._0
                              ]);
                  }
                  
                }
                if (!Caml_obj.equal(consumed, [])) {
                  throw {
                        RE_EXN_ID: "Assert_failure",
                        _1: [
                          "arcdown.res",
                          348,
                          10
                        ],
                        Error: new Error()
                      };
                }
                consumeRegularLine(line);
                return Promise.resolve([
                            false,
                            lnum,
                            subs,
                            ""
                          ]);
              }
              consumeRegularLine(line);
              return Promise.resolve([
                          false,
                          lnum,
                          subs,
                          ""
                        ]);
            });
}

var attrs = "";

function promi(param) {
  var attrs = param[3];
  var subs = param[2];
  var lnum = param[1];
  return $$Promise.$$catch($$Promise.$$catch(param[0] ? consumeInitialLine(lnum, subs, attrs, "") : consumeLine(lnum, subs, attrs, ""), (function (err) {
                      if (err.RE_EXN_ID === EndOfFile) {
                        console.log("DONE");
                        return Promise.reject(err);
                      } else {
                        console.log("Unexpected error");
                        return Promise.reject(err);
                      }
                    })).then(promi), (function (param) {
                return Promise.resolve(undefined);
              }));
}

promi([
      true,
      0,
      /* [] */0,
      attrs
    ]);

var backtick = "`";

var outputFormat = /* Html */0;

var subs = /* [] */0;

var lnum = 0;

exports.backtick = backtick;
exports.spaces = spaces;
exports.source = source;
exports.alpha = alpha;
exports.alnum = alnum;
exports.getMatches = getMatches;
exports.EndOfFile = EndOfFile;
exports.lines = lines;
exports.nextLine = nextLine;
exports.outputFormat = outputFormat;
exports.specialCharsStep = specialCharsStep;
exports.consumeBlockTitle = consumeBlockTitle;
exports.consumeHeading = consumeHeading;
exports.consumeSubstitution = consumeSubstitution;
exports.consumeAttribute = consumeAttribute;
exports.consumeHyperlink = consumeHyperlink;
exports.consumeLabel = consumeLabel;
exports.consumeBulletListItem = consumeBulletListItem;
exports.consumeNumberedListItem = consumeNumberedListItem;
exports.consumeRegularLine = consumeRegularLine;
exports.EndOfBlock = EndOfBlock;
exports.consumeRegularBlock = consumeRegularBlock;
exports.consumeInitialLine = consumeInitialLine;
exports.consumeLine = consumeLine;
exports.subs = subs;
exports.attrs = attrs;
exports.lnum = lnum;
exports.promi = promi;
/* lines Not a pure module */
