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

var source = "\n[NOTE]\n====\nThis is how to start a new example\nblock within this block:\n\n.Nested block\n[example]\n====\nA small example\n====\n====\n";

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
  var checkEndBlock = function (ln, attrs) {
    if (attrs === "") {
      return getMatches(blockLine, ln).length !== 0;
    } else {
      return false;
    }
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
              if (endchar === chara && Curry._2(confirm, line, attrs)) {
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
  return $$Promise.$$catch($$Promise.$$catch(consumeLine(param[0], param[1], param[2], "$", (function (param, param$1) {
                          return false;
                        })), (function (err) {
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
      0,
      /* [] */0,
      attrs
    ]);

var backtick = "`";

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
