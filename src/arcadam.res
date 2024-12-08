let backtick = "`"

let source = `
[NOTE]
====
This is how to start a new example
block within this block:

[example]
====
Nested block<
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
>   > ** sublist
>>    ** one more
    >  1... nested numbered list
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

  Indented text is added
  * to a code block

  code block continued

// comment

\tAnother code block

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
  switch regex->RegExp.exec(someline) {
  | Some(result) => result->RegExp.Result.matches
  | None => []
  }

let countSpaces = line => {
  let spacesIndent = %re("/^([ ]+)/")
  switch spacesIndent->getMatches(line) {
  | [indent] => indent->String.length
  | _ => 0
  }
}

exception EndOfFile(string)
let lines = source->String.split("\n")

let nextLine = lnum =>
  switch lines[lnum] {
  | Some(line) =>
    let count = countSpaces(line)
    resolve((line->String.trim, lnum + 1, count))
  | None => reject(EndOfFile("EOF"))
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
  | IndentedText(string)
  | CodeText(string)
  | Heading(int) // ## Heading text
  | Attribute(string) // [attributes]
  | BulletListItem(int) // * List item
  | NumberedListItem(int) // . List item
  | IndentedBulletListItem(int) // * List item
  | IndentedNumberedListItem(int) // . List item
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

type lineType =
  | Initial
  | Following
  | Code
  | Indented
  | List

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
  let titleLine = %re("/^(#+)\s+([^\s].*)$/")
  switch titleLine->getMatches(line) {
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
  let attrLine = %re("/^\[\s*([^\[\]]*)\]$/")
  switch attrLine->getMatches(line) {
  | [attributes] => [Attribute(attributes)]
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
    switch line->String.charAt(0) {
    | "*" => [BulletListItem(level), Text(text)]
    | _ => [IndentedBulletListItem(level), IndentedText(text)]
    }
  | _ => []
  }
}

let consumeNumberedListItem = line => {
  let itemLine = %re("/^1?([.]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [dots, text] =>
    let level = dots->String.length
    switch line->String.charAt(0) {
    | "." | "1" => [NumberedListItem(level), Text(text)]
    | _ => [IndentedNumberedListItem(level), IndentedText(text)]
    }
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

let rec consumeRegularLine = line => {
  let chara = line->String.charAt(0)
  let tok = switch chara {
  | "[" => consumeHyperlink(line)
  | "*" => consumeBulletListItem(line)
  | ">" =>
    let indents = consumeIndentSigns(line)
    switch indents {
    | [IndentSigns(_num, nchars)] =>
      let rest = line->String.sliceToEnd(~start=nchars)
      indents->Array.concat(consumeRegularLine(rest))
    | _ => [Text(line)]
    }
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
      let chara = line->String.charAt(0)
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
      | _ =>
        let tokens = consumeRegularLine(line)
        resolve((tok->Array.concat(tokens), Following, lnum))
      }
    }
  }
}

let consumeInitialLine = (tok, lnum) =>
  nextLine(lnum)->then(((line, lnum, nspaces)) => {
    if nspaces > 0 {
      let tokens = [Spaces(nspaces), CodeText(line)]
      resolve((tok->Array.concat(tokens), Code, lnum))
    } else {
      tokeniseInitialLine(line, tok, lnum)
    }
  })

let consumeLine = (tok, lnum) =>
  nextLine(lnum)->then(((line, lnum, nspaces)) => {
    let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
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
  nextLine(lnum)->then(((line, lnum, nspaces)) => {
    let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
    if line == "```" {
      resolve((tok->Array.concat([CodeBlockDelimiter]), Initial, lnum))
    } else {
      resolve((tok->Array.concat([CodeText(line)]), Code, lnum))
    }
  })

let consumeIndentedLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum, nspaces)) => {
    if nspaces > 0 {
      let tokens = [Spaces(nspaces), IndentedText(line)]
      resolve((tok->Array.concat(tokens), Indented, lnum))
    } else {
      tokeniseInitialLine(line, tok, lnum)
    }
  })
}

let consumeListLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum, nspaces)) => {
    let tok = nspaces > 0 ? tok->Array.concat([Spaces(nspaces)]) : tok
    if line != "" {
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
      consumeInitialLine(tok->Array.concat([Empty]), lnum)
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
  let pattern = `^\\s*([!-@[-${backtick}|~][${alpha}]([${alnum}])*)`
  let markerExpr = RegExp.fromString(pattern)
  switch markerExpr->getMatches(atext) {
  | [name, _] => Console.log2("Parse: marker", name)
  | k => Console.log2("Failed to parse:", k)
  }
}

type parseState =
  | General
  | Replacement(string)

let parseDocument = tok => {
  let _attributes = Map.make()
  let _substitutions = Map.make()
  let state = ref(General)
  tok->Array.forEach(token =>
    switch token {
    | Attribute(attributeList) => parseAttribute(attributeList, _attributes)
    | Marker(marker) => parseMarker(marker)
    | ReplacementKey(name) => state := Replacement(name)
    | Text(value) =>
      switch state.contents {
      | Replacement(name) =>
        Console.log4("Parse: will replace reference", name, "with", value)
        state := General
        _substitutions->Map.set(name, value)
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
      tok->Array.forEach(token => Console.log2("T: ", token))
      Console.log(`DONE ${tok->Array.length->string_of_int}`)
      tok->parseDocument
      resolve()
    | _ =>
      Console.log("Unexpected error")
      resolve()
    }
  )
promi(([], Initial, lnum))->ignore