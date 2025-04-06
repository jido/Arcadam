let loadSample = () => {
  let v = NodeJs.Fs.readFileSyncWith("sample.arcd", {encoding: "utf8"})
  v->NodeJs.Buffer.toString
}

open Promise

let alpha = "A-Za-z"
let alnum = "0-9" ++ alpha
let backtick = "`"
let tablen = 4

let getMatches = (regex, someline) =>
  switch regex->RegExp.exec(someline) {
  | Some(result) =>
    result
    ->Array.sliceToEnd(~start=1)
    ->Array.map(opt =>
      switch opt {
      | None => ""
      | Some(text) => text
      }
    )
  | None => []
  }

let countSpaces = line => {
  let initialSpaces = %re("/^([ \t]+)/")
  switch getMatches(initialSpaces, line) {
  | [spaces] => {
      let count = ref(0)
      for i in 0 to spaces->String.length - 1 {
        let c = spaces->String.charAt(i)
        switch c {
        | " " => count := count.contents + 1
        | "\t" => count := tablen * (count.contents / tablen) + tablen
        | _ => Console.error("unreachable")
        }
      }
      count.contents
    }
  | _ => 0
  }
}

exception EndOfFile(string)
let lines = loadSample()->String.split("\n")

let nextLine = async (lnum, codeIndent) => {
  switch lines[lnum] {
  | Some(line) =>
    let count = countSpaces(line)
    let codeIndent =
      count > 0 || line->String.length == 0
        ? codeIndent
        : String.indexOf(">.", line->String.charAt(0)) == -1
    (line->String.trim, lnum + 1, codeIndent, count)
  | None => raise(EndOfFile("EOF"))
  }
}

type formats =
  | Html
  | Asciidoc

let outputFormat = Html

let specialCharsStep = text =>
  switch outputFormat {
  | Html =>
    let result = text->String.replaceAllRegExp(%re("/&/g"), "&amp;")
    let result = result->String.replaceAllRegExp(%re("/</g"), "&lt;")
    result->String.replaceAllRegExp(%re("/>/g"), "&gt;")
  | Asciidoc => text
  }

type token =
  | Empty
  | Text(string)
  | CodeText(string)
  | IndentedCode(string)
  | Heading(int) // ## Heading text
  | Attribute(string) // [attributes]
  | BulletListItem(int) // * List item
  | NumberedListItem(int) // . List item
  | IndentSigns(int, int) // >
  | Spaces(int)
  | Nesting(int) // Dots alone
  | Marker(string) // [marker]:
  | ReplacementKey(string) // :key:name value
  | Hyperlink(string) // [text](address)
  | FreeBlockDelimiter // --
  | CodeBlockDelimiter // ```
  | QuoteBlockDelimiter // ___
  | ExampleBlockDelimiter // ====
  | SidebarBlockDelimiter // ****
  | ContentBlockDelimiter // ~~~~
  | BlockTitle(string) // = Block title
  | ReplacementUse(string) // {name}
  | StandaloneControl(string, string) // [!type params](options)
  | InlineControl(string, string) // [?type params](options)
  | ControlOptions(string)

type lineType =
  | Initial(bool)
  | Following(bool)
  | Code(bool)
  | Indented
  | List(bool)

let consumeIndentSigns = line => {
  let indentSign = %re("/^((>\s*)*>\s+)/")
  switch indentSign->getMatches(line) {
  | [indent, _] =>
    let onlySigns = indent->String.replaceAllRegExp(%re("/\s+/g"), "")
    [IndentSigns(onlySigns->String.length, indent->String.length)]
  | _ => []
  }
}

let consumeBlockTitle = line => {
  let blockTitleLine = %re("/^=\s+(.*)$/")
  switch blockTitleLine->getMatches(line) {
  | [title] => [BlockTitle(title)]
  | _ => []
  }
}

let consumeHeading = line => {
  let headingLine = %re("/^(#+)\s+([^\s].*)$/")
  switch headingLine->getMatches(line) {
  | [signs, title] =>
    let level = signs->String.length
    [Heading(level), Text(title)]
  | _ => []
  }
}

let consumeReplacement = line => {
  let pattern = `^:key:([${alpha}][_${alnum}]*(\\.[_${alnum}]+)*)\\s+(.*)\$`
  let substLine = RegExp.fromString(pattern)
  switch substLine->getMatches(line) {
  | [name, _, value] => [ReplacementKey(name), Text(value)]
  | _ => []
  }
}

let consumeAttribute = line => {
  let attrLine = %re("/^\[\s*([^\[\]]*)\]\s*$/")
  switch attrLine->getMatches(line) {
  | [attributes] => [Attribute(attributes)]
  | _ => []
  }
}

let consumeInlineControl = line => {
  // TODO: handle brackets inside quotes
  let controlLine = %re("/\[\s*\?\s*([^ \]]*)(\s+[^\]]+)?\s*\]\((.*)\)/")
  switch controlLine->getMatches(line) {
  | [controlType, params, ""] => [InlineControl(controlType, params)]
  | [controlType, params, options] => [InlineControl(controlType, params), ControlOptions(options)]
  | _ => []
  }
}

let consumeStandaloneControl = line => {
  // TODO: handle brackets inside quotes
  let controlLine = %re("/^\[\s*!\s*([^ \]]*)(\s+[^\]]+)?\s*\](\((.*)\))?\s*$/")
  switch controlLine->getMatches(line) {
  | [controlType, params, _, ""] => [StandaloneControl(controlType, params)]
  | [controlType, params, _, options] => [
      StandaloneControl(controlType, params),
      ControlOptions(options),
    ]
  | _ => []
  }
}

let consumeHyperlink = line => {
  let hlinkLine = %re("/\[\s*([^\]]*)\]\(\s*([^\s\)]*)\s*\)/")
  switch hlinkLine->getMatches(line) {
  | [text, link] => [Hyperlink(link), Text(text)] // do NOT merge text token with the next
  | _ => []
  }
}

let consumeMarker = line => {
  let markerLine = %re("/^\[\s*([^\]]+)\]:\s*$/")
  switch markerLine->getMatches(line) {
  | [marker] => [Marker(marker)]
  | _ => []
  }
}

let consumeBulletListItem = line => {
  let itemLine = %re("/^([*]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [stars, text] =>
    let level = stars->String.length
    [BulletListItem(level), Text(text)]
  | _ => []
  }
}

let consumeNumberedListItem = line => {
  let itemLine = %re("/^1?([.]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [dots, text] =>
    let level = dots->String.length
    [NumberedListItem(level), Text(text)]
  | _ => []
  }
}

let consumeNestingSigns = line => {
  let itemLine = %re("/^([.]+)\s*$/")
  switch itemLine->getMatches(line) {
  | [dots] =>
    let level = dots->String.length
    [Nesting(level)]
  | _ => []
  }
}

let consumeBlockDelimiter = line =>
  switch line {
  | "" => [Empty]
  | "--" => [FreeBlockDelimiter]
  | "```" => [CodeBlockDelimiter]
  | "___" => [QuoteBlockDelimiter]
  | "====" => [ExampleBlockDelimiter]
  | "****" => [SidebarBlockDelimiter]
  | "~~~~" => [ContentBlockDelimiter]
  | _ => []
  }

let consumeRegularLine = line => {
  let tokens = consumeBlockDelimiter(line)
  switch tokens {
  | [CodeBlockDelimiter] => [Text(line)]
  | [_] => tokens
  | _ =>
    let chara = line->String.charAt(0)
    let tok = switch chara {
    | "[" =>
      let tokens = consumeMarker(line)
      if tokens != [] {
        tokens
      } else {
        let tokens = consumeStandaloneControl(line)
        if tokens != [] {
          tokens
        } else {
          let tokens = consumeInlineControl(line)
          if tokens != [] {
            tokens
          } else {
            consumeHyperlink(line)
          }
        }
      }
    | "*" => consumeBulletListItem(line)
    | "." | "1" => consumeNumberedListItem(line)
    | _ => []
    }
    if tok == [] {
      [Text(line)]
    } else {
      tok
    }
  }
}

let tokeniseLine = (line, tok, lnum, codeIndent) =>
  if line == "" {
    resolve((tok->Array.concat([Empty]), Initial(codeIndent), lnum))
  } else {
    let chara = line->String.charAt(0)
    let tokens = switch chara {
    | "." => consumeNestingSigns(line)
    | ">" =>
      let indents = consumeIndentSigns(line)
      switch indents {
      | [IndentSigns(_num, nchars)] =>
        let rest = line->String.sliceToEnd(~start=nchars)
        indents->Array.concat(consumeRegularLine(rest))
      | _ => []
      }
    | _ => []
    }
    switch tokens {
    | [BulletListItem(_level) | NumberedListItem(_level), _] =>
      resolve((tok->Array.concat(tokens), List(codeIndent), lnum))
    | [] =>
      let tokens = consumeRegularLine(line)
      resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
    | _ => resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
    }
  }

let consumeLineFactory = tokeniser => (tok, lnum, codeIndent) =>
  nextLine(lnum, codeIndent)->then(((line, lnum, codeIndent, nspaces)) =>
    if nspaces > 0 {
      if codeIndent {
        let tokens = [Spaces(nspaces), IndentedCode(line)]
        resolve((tok->Array.concat(tokens), Indented, lnum))
      } else {
        let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
        tokeniser(line, tok, lnum, codeIndent)
      }
    } else {
      tokeniser(line, tok, lnum, codeIndent)
    }
  )

let consumeLine = consumeLineFactory(tokeniseLine)

exception EndOfBlock(array<token>)

let rec tokeniseInitialLine = (line, tok, lnum, codeIndent) => {
  let tokens = consumeBlockDelimiter(line)
  switch tokens {
  | [CodeBlockDelimiter] => resolve((tok->Array.concat(tokens), Code(codeIndent), lnum))
  | [_] => resolve((tok->Array.concat(tokens), Initial(codeIndent), lnum))
  | _ => {
      let chara = line->String.charAt(0)
      switch chara {
      | "=" =>
        let tokens = consumeBlockTitle(line)
        switch tokens {
        | [BlockTitle(_title)] => resolve((tok->Array.concat(tokens), Initial(codeIndent), lnum))
        | _ =>
          assert(tokens == [])
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
        }
      | "#" =>
        let tokens = consumeHeading(line)
        if tokens != [] {
          resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
        } else {
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
        }
      | ":" =>
        let tokens = consumeReplacement(line)
        switch tokens {
        | [ReplacementKey(_name), Text(_value)] =>
          //let subs = subs->List.add((name, value))
          resolve((tok->Array.concat(tokens), Initial(codeIndent), lnum))
        | _ =>
          assert(tokens == [])
          resolve((consumeRegularLine(line), Following(codeIndent), lnum))
        }
      | "[" =>
        let tokens = consumeAttribute(line)
        switch tokens {
        | [Attribute(_attributes)] =>
          resolve((tok->Array.concat(tokens), Initial(codeIndent), lnum))
        | _ =>
          assert(tokens == [])
          let tokens = consumeMarker(line)
          if tokens != [] {
            resolve((tok->Array.concat(tokens), Initial(codeIndent), lnum))
          } else {
            let tokens = consumeRegularLine(line)
            resolve((tok->Array.concat(tokens), Following(codeIndent), lnum))
          }
        }
      | ">" =>
        let indents = consumeIndentSigns(line)
        switch indents {
        | [IndentSigns(_num, nchars)] =>
          let rest = line->String.sliceToEnd(~start=nchars)
          tokeniseInitialLine(rest, tok->Array.concat(indents), lnum, false)
        | _ => tokeniseLine(line, tok, lnum, codeIndent)
        }
      | _ => tokeniseLine(line, tok, lnum, codeIndent)
      }
    }
  }
}

let consumeInitialLine = consumeLineFactory(tokeniseInitialLine)

let consumeCodeLine = (tok, lnum, codeIndent) =>
  nextLine(lnum, codeIndent)->then(((line, lnum, codeIndent, nspaces)) => {
    let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
    if line == "```" {
      resolve((tok->Array.concat([CodeBlockDelimiter]), Initial(codeIndent), lnum))
    } else {
      resolve((tok->Array.concat([CodeText(line)]), Code(codeIndent), lnum))
    }
  })

let consumeIndentedCode = (tok, lnum) =>
  nextLine(lnum, true)->then(((line, lnum, codeIndent, nspaces)) => {
    if nspaces > 0 {
      let tokens = [Spaces(nspaces), IndentedCode(line)]
      resolve((tok->Array.concat(tokens), Indented, lnum))
    } else {
      tokeniseInitialLine(line, tok, lnum, codeIndent)
    }
  })

let consumeListLine = (tok, lnum, codeIndent) => {
  nextLine(lnum, codeIndent)->then(((line, lnum, codeIndent, nspaces)) => {
    if line != "" {
      let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
      let tokens = consumeBulletListItem(line)
      if tokens == [] {
        let tokens = consumeNumberedListItem(line)
        if tokens == [] {
          resolve((tok->Array.concat([Text(line)]), List(codeIndent), lnum))
        } else {
          resolve((tok->Array.concat(tokens), List(codeIndent), lnum))
        }
      } else {
        resolve((tok->Array.concat(tokens), List(codeIndent), lnum))
      }
    } else {
      tokeniseInitialLine(line, tok, lnum, codeIndent)
    }
  })
}

let parseAttribute = (atext, attributes) => {
  let pattern = `^\\s*([.]?[${alpha}]([.]?[${alnum}])*)`
  let attrExpr = RegExp.fromString(pattern)
  switch attrExpr->getMatches(atext) {
  | [name, _] =>
    Console.log2("Parse: attribute", name)
    attributes->Map.set(name, "")
  | k => Console.log2("Failed to parse:", k)
  }
}

let parseMarker = atext => {
  let pattern = `^\\s*([!-@\[-${backtick}|~])\\s*([${alpha}]([${alnum}])*)(.*)`
  let markerExpr = RegExp.fromString(pattern)
  switch markerExpr->getMatches(atext) {
  | [symbol, name, _, args] => Console.log6("Parse: marker", name, "prefix:", symbol, "rest:", args)
  | _ => Console.log2("Failed to parse:", atext)
  }
}

type parseState =
  | General
  | Replacement(string)
  | Hyperlink(string)

module type ParserOutput = {
  let outputHyperlink: (string, string) => unit
  let outputText: string => unit
}

let parseDocument = (tok, module(Output: ParserOutput)) => {
  let _attributes = Map.make()
  let _replacements = Map.make()
  let state = ref(General)
  tok->Array.forEach(token =>
    switch token {
    | Attribute(attributeList) => parseAttribute(attributeList, _attributes)
    | Marker(marker) => parseMarker(marker)
    | ReplacementKey(name) => state := Replacement(name)
    | Hyperlink(target) => state := Hyperlink(target)
    | Text(value) =>
      switch state.contents {
      | Replacement(name) =>
        //Console.log4("Parse: will replace reference", name, "with", value)
        state := General
        _replacements->Map.set(name, value)
      | Hyperlink(target) =>
        Output.outputHyperlink(target, value)
        state := General
      | General =>
        Output.outputText(value)
        assert(true)
      }
    | _ =>
      // do nothing
      assert(true)
    }
  )
  _replacements->Map.forEachWithKey((value, name) => Console.log4("Key:", name, "Value:", value))
}

let subs = list{}
let attrs = ""
let lnum = 0

exception Success(array<token>)

let rec promi = ((tok, ltype, lnum)) =>
  switch ltype {
  | Initial(codeIndent) => consumeInitialLine(tok, lnum, codeIndent)
  | Following(codeIndent) => consumeLine(tok, lnum, codeIndent)
  | Code(codeIndent) => consumeCodeLine(tok, lnum, codeIndent)
  | Indented => consumeIndentedCode(tok, lnum)
  | List(codeIndent) => consumeListLine(tok, lnum, codeIndent)
  }
  ->then(promi)
  ->catch(err =>
    switch err {
    | EndOfFile(_) =>
      tok->Array.forEach(token => Console.log2("T: ", token))
      Console.log(`DONE ${tok->Array.length->string_of_int}`)
      tok->parseDocument(module(HtmlOutput))
      resolve()
    | _ =>
      Console.log("Unexpected error")
      resolve()
    }
  )
promi(([], Initial(true), lnum))->ignore