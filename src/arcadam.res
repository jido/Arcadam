open Belt

let backtick = "`"

let source = `
[NOTE]
====
This is how to start a new example
block within this block:

[example]
====
.Nested block<
A small example
====
====

:key:subs value&more
## Arcadam Test ->> part 1

[Go to ${backtick}Products page${backtick} on this site](/Products.html)

[Go to _Offers page_ in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)

[#anchor]:
Part 1: This text is selected by the anchor.

[<Go to *Part 1*>](#anchor)

[Arcadam Test ->> part 1]()

___
Quote text using
underscores
___

====
Example block used to
enclose an example
====

****
Sidebar block used to
expand on a topic or
highlight an idea
****

Paragraph:
* First<
multi line
* Second&&
> * first sublist
    ** sublist
    ** one more
      1... nested numbered list
      on two lines
      ... nested 2
..
    That was all for first sublist.
* Third
[list]
. Number one

= Block title
${backtick}${backtick}${backtick}
unindented code block
  indented line inside code block
${backtick}${backtick}${backtick}

  Indented text without
  * line breaks is added
  to a code block

  Normal paragraph after code block

  Another paragraph

${backtick}${backtick}${backtick}
Another way to create
a code block delimited
with ${backtick}${backtick}${backtick}

****
This is not a new block
${backtick}${backtick}${backtick}

[-begin region]:
This text can be included
on its own.
[-end region]:
New block starts after marker

[.styleclass]
[mylist.first]
Testing dotted attributes
`

open Promise

let alpha = "A-Za-z"
let alnum = "0-9" ++ alpha

let getMatches = (regex, someline) =>
  switch regex->Js.Re.exec_(someline) {
  | Some(result) =>
    Js.Re.captures(result)->Array.map(x => Js.Nullable.toOption(x)->(Option.getWithDefault(_, "")))
  | None => []
  }

exception EndOfFile(string)
let lines = "\n"->Js.String.split(source)

let nextLine = lnum =>
  switch lines[lnum] {
  | Some(line) =>
    let trimEnd = %re("/^((\s*[^\s]+)*)\s*$/")
    switch trimEnd->getMatches(line) {
    | [_, line, _] => resolve((line, lnum + 1))
    | _ => resolve(("", lnum + 1))
    }
  | None => reject(EndOfFile("EOF"))
  }

type formats =
  | Html
  | Asciidoc

let outputFormat = Html

let specialCharsStep = text =>
  switch outputFormat {
  | Html =>
    let result = Js.String.replaceByRe(%re("/&/g"), "&amp;", text)
    let result = Js.String.replaceByRe(%re("/</g"), "&lt;", result)
    Js.String.replaceByRe(%re("/>/g"), "&gt;", result)
  | Asciidoc => text
  }

type token =
  | Empty
  | Text(string)
  | IndentedText(string)
  | CodeText(string)
  | Heading(int) // ## Heading text
  | Attribute(string) // [attributes]
  | BulletListItem(int) // * List item
  | NumberedListItem(int) // . List item
  | IndentedBulletListItem(int) // * List item
  | IndentedNumberedListItem(int) // . List item
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

type lineType =
  | Initial
  | Following
  | Code
  | Indented
  | List

let consumeBlockTitle = line => {
  let blockTitleLine = %re("/^=\s+(.*)$/")
  switch blockTitleLine->getMatches(line) {
  | [_, title] => [BlockTitle(title)]
  | _ => []
  }
}

let consumeHeading = line => {
  let titleLine = %re("/^(#+)\s+([^\s].*)$/")
  switch titleLine->getMatches(line) {
  | [_, signs, title] =>
    let level = signs->String.length
    [Heading(level), Text(title)]
  | _ => []
  }
}

let consumeReplacement = line => {
  let pattern = `^:key:([${alpha}][_${alnum}]*(\\.[_${alnum}]+)*)\\s+(.*)\$`
  let substLine = Js.Re.fromString(pattern)
  switch substLine->getMatches(line) {
  | [_, name, _, value] => [ReplacementKey(name), Text(value)]
  | _ => []
  }
}

let consumeAttribute = line => {
  let attrLine = %re("/^\[\s*([^\[\]]*)\]$/")
  switch attrLine->getMatches(line) {
  | [_, attributes] => [Attribute(attributes)]
  | _ => []
  }
}

let consumeHyperlink = line => {
  let hlinkLine = %re("/\[\s*([^\]]*)\]\(\s*([^\s\)]*)\s*\)/")
  switch hlinkLine->getMatches(line) {
  | [_, text, link] => [Hyperlink(link), Text(text)] // do NOT merge text token with the next
  | _ => []
  }
}

let consumeMarker = line => {
  let markerLine = %re("/^\[\s*([^\]]+)\]:\s*$/")
  switch markerLine->getMatches(line) {
  | [_, marker] => [Marker(marker)]
  | _ => []
  }
}

let consumeBulletListItem = line => {
  let itemLine = %re("/^\s*([*]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [_, stars, text] =>
    let level = stars->String.length
    switch Js.String.charAt(0, line) {
    | "*" => [BulletListItem(level), Text(text)]
    | _ => [IndentedBulletListItem(level), IndentedText(text)]
    }
  | _ => []
  }
}

let consumeNumberedListItem = line => {
  let itemLine = %re("/^\s*1?([.]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [_, dots, text] =>
    let level = dots->String.length
    switch Js.String.charAt(0, line) {
    | "." | "1" => [NumberedListItem(level), Text(text)]
    | _ => [IndentedNumberedListItem(level), IndentedText(text)]
    }
  | _ => []
  }
}

let consumeNestingSigns = line => {
  let itemLine = %re("/^([.]+)\s*$/")
  switch itemLine->getMatches(line) {
  | [_, dots] =>
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
  let chara = Js.String.charAt(0, line)
  let tok = switch chara {
  | "[" => consumeHyperlink(line)
  | "*" => consumeBulletListItem(line)
  | "." =>
    let nesting = consumeNestingSigns(line)
    switch nesting {
    | [Nesting(_level)] => nesting
    | _ => consumeNumberedListItem(line)
    }
  | _ => []
  }
  if tok == [] {
    [Text(line)]
  } else {
    tok
  }
}

exception EndOfBlock(array<token>)

let tokeniseInitialLine = (line, tok, lnum) => {
  let tokens = consumeBlockDelimiter(line)
  switch tokens {
  | [CodeBlockDelimiter] => resolve((tok->Array.concat(tokens), Code, lnum))
  | [_] => resolve((tok->Array.concat(tokens), Initial, lnum))
  | _ => {
      let chara = Js.String.charAt(0, line)
      switch chara {
      | "=" =>
        let tokens = consumeBlockTitle(line)
        switch tokens {
        | [BlockTitle(_title)] => resolve((tok->Array.concat(tokens), Initial, lnum))
        | _ =>
          assert(tokens == [])
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), Following, lnum))
        }
      | "#" =>
        let tokens = consumeHeading(line)
        if tokens != [] {
          resolve((tok->Array.concat(tokens), Following, lnum))
        } else {
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), Following, lnum))
        }
      | ":" =>
        let tokens = consumeReplacement(line)
        switch tokens {
        | [ReplacementKey(_name), Text(_value)] =>
          //let subs = subs->List.add((name, value))
          resolve((tok->Array.concat(tokens), Initial, lnum))
        | _ =>
          assert(tokens == [])
          resolve((consumeRegularLine(line), Following, lnum))
        }
      | "[" =>
        let tokens = consumeAttribute(line)
        switch tokens {
        | [Attribute(_attributes)] => resolve((tok->Array.concat(tokens), Following, lnum))
        | _ =>
          assert(tokens == [])
          let tokens = consumeMarker(line)
          if tokens != [] {
            resolve((tok->Array.concat(tokens), Initial, lnum))
          } else {
            let tokens = consumeRegularLine(line)
            resolve((tok->Array.concat(tokens), Following, lnum))
          }
        }
      | " " | "\t" =>
        let tokens = consumeBulletListItem(line)
        if tokens == [] {
          let tokens = consumeNumberedListItem(line)
          if tokens == [] {
            resolve((tok->Array.concat([IndentedText(line)]), Indented, lnum))
          } else {
            resolve((tok->Array.concat(tokens), List, lnum))
          }
        } else {
          resolve((tok->Array.concat(tokens), List, lnum))
        }
      | _ =>
        let tokens = consumeRegularLine(line)
        resolve((tok->Array.concat(tokens), Following, lnum))
      }
    }
  }
}

let consumeInitialLine = (tok, lnum) =>
  nextLine(lnum)->then(((line, lnum)) => {
    tokeniseInitialLine(line, tok, lnum)
  })

let consumeLine = (tok, lnum) =>
  nextLine(lnum)->then(((line, lnum)) => {
    let tokens = consumeBlockDelimiter(line)
    if tokens->Array.length != 0 {
      resolve((tok->Array.concat(tokens), Initial, lnum))
    } else {
      let tokens = consumeAttribute(line)
      switch tokens {
      | [Attribute(_attributes)] => resolve((tok->Array.concat(tokens), Following, lnum))
      | _ =>
        assert(tokens == []) // Appease the compiler
        let tokens = consumeMarker(line)
        switch tokens {
        | [Marker(_marker)] => resolve((tok->Array.concat(tokens), Initial, lnum))
        | _ =>
          assert(tokens == []) // Appease the compiler
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), Following, lnum))
        }
      }
    }
  })

let consumeCodeLine = (tok, lnum) =>
  nextLine(lnum)->then(((line, lnum)) => {
    if line == "```" {
      resolve((tok->Array.concat([CodeBlockDelimiter]), Initial, lnum))
    } else {
      resolve((tok->Array.concat([CodeText(line)]), Code, lnum))
    }
  })

let consumeIndentedLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum)) => {
    let chara = Js.String.charAt(0, line)
    if chara == " " || chara == "\t" {
      let tokens = [IndentedText(line)]
      resolve((tok->Array.concat(tokens), Indented, lnum))
    } else {
      tokeniseInitialLine(line, tok, lnum)
    }
  })
}

let consumeListLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum)) => {
    let chara = Js.String.charAt(0, line)
    if chara == " " || chara == "\t" {
      let tokens = consumeBulletListItem(line)
      if tokens == [] {
        let tokens = consumeNumberedListItem(line)
        if tokens == [] {
          resolve((tok->Array.concat([IndentedText(line)]), List, lnum))
        } else {
          resolve((tok->Array.concat(tokens), List, lnum))
        }
      } else {
        resolve((tok->Array.concat(tokens), List, lnum))
      }
    } else {
      tokeniseInitialLine(line, tok, lnum)
    }
  })
}

let parseAttribute = (atext, attributes) => {
  let pattern = `^\\s*([.]?[${alpha}]([.]?[${alnum}])*)`
  let attrExpr = Js.Re.fromString(pattern)
  switch attrExpr->getMatches(atext) {
  | [_, name, _] =>
    Js.log2("Parse: attribute", name)
    attributes->HashMap.String.set(name, "")
  | k => Js.log2("Failed to parse:", k)
  }
}

let parseMarker = atext => {
  let pattern = `^\\s*([!-@[-${backtick}|~][${alpha}]([${alnum}])*)`
  let markerExpr = Js.Re.fromString(pattern)
  switch markerExpr->getMatches(atext) {
  | [_, name, _] => Js.log2("Parse: marker", name)
  | k => Js.log2("Failed to parse:", k)
  }
}

type parseState =
  | General
  | Replacement(string)

let parseDocument = tok => {
  let _attributes = HashMap.String.make(~hintSize=10)
  let _substitutions = HashMap.String.make(~hintSize=30)
  let state = ref(General)
  tok->Array.forEach(token =>
    switch token {
    | Attribute(attributeList) => parseAttribute(attributeList, _attributes)
    | Marker(marker) => parseMarker(marker)
    | ReplacementKey(name) => state := Replacement(name)
    | Text(value) =>
      switch state.contents {
      | Replacement(name) =>
        Js.log4("Parse: will replace reference", name, "with", value)
        state := General
        _substitutions->HashMap.String.set(name, value)
      | General =>
        // do nothing
        assert(true)
      }
    | _ =>
      // do nothing
      assert(true)
    }
  )
}

let subs = list{}
let attrs = ""
let lnum = 0

exception Success(array<token>)

let rec promi = ((tok, ltype, lnum)) =>
  switch ltype {
  | Initial => consumeInitialLine(tok, lnum)
  | Following => consumeLine(tok, lnum)
  | Code => consumeCodeLine(tok, lnum)
  | Indented => consumeIndentedLine(tok, lnum)
  | List => consumeListLine(tok, lnum)
  }
  ->then(promi)
  ->catch(err =>
    switch err {
    | EndOfFile(_) =>
      tok->Array.forEach(token => Js.log2("T: ", token))
      Js.log(`DONE ${tok->Array.length->string_of_int}`)
      tok->parseDocument
      resolve()
    | _ =>
      Js.log("Unexpected error")
      resolve()
    }
  )
promi(([], Initial, lnum))->ignore