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

let consumeLineFactory = tokeniser => ((line, lnum: int, codeIndent, nspaces, tok)) =>
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

let consumeCodeLine = ((line, lnum, codeIndent, nspaces, tok)) => {
  let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
  if line == "```" {
    resolve((tok->Array.concat([CodeBlockDelimiter]), Initial(codeIndent), lnum))
  } else {
    resolve((tok->Array.concat([CodeText(line)]), Code(codeIndent), lnum))
  }
}

let consumeIndentedCode = ((line, lnum, codeIndent, nspaces, tok)) => {
  if nspaces > 0 {
    let tokens = [Spaces(nspaces), IndentedCode(line)]
    resolve((tok->Array.concat(tokens), Indented, lnum))
  } else {
    tokeniseInitialLine(line, tok, lnum, codeIndent)
  }
}

let consumeListLine = ((line, lnum: int, codeIndent, nspaces, tok)) => {
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
}