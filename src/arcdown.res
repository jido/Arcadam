open Belt

let backtick = "`"
let spaces = "      "

let source = `
[NOTE]
====
This is how to start a new example
block within this block:
${spaces}
.Nested block<
[example]
====
A small example
====
====

:subs: value&more
== Arcdown Test ->> part 1

[Go to Products page on this site](/Products.html)

[Go to Offers page in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)

[#anchor]:
Part 1: This text is selected by the anchor.

[<Go to Part 1>](#anchor)

____
Quote text using
underscores
____

====
Example block used to
enclose an example
====

****
Sidebar block used to
expand on a topic or
highlight an idea
****

* First<
multi line
* Second&&
** sublist
** one more
... nested numbered list
... nested 2
* Third
[list]
. Number one
`

open Promise

let alpha = "A-Za-z"
let alnum = "0-9" ++ alpha

let getMatches = (regex, someline) =>
  switch regex->Js.Re.exec_(someline) {
  | Some(result) =>
    Js.Re.captures(result)->Array.map(x => Js.Nullable.toOption(x)->Option.getWithDefault(_, ""))
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

let specialCharsStep = text => {
  switch outputFormat {
  | Html =>
    let result = Js.String.replaceByRe(%re("/&/g"), "&amp;", text)
    let result = Js.String.replaceByRe(%re("/</g"), "&lt;", result)
    Js.String.replaceByRe(%re("/>/g"), "&gt;", result)
  | Asciidoc => text
  }
}

type token =
  | Text(string)
  | Heading(int) // == Heading text
  | Attribute(string) // [attributes]
  | BulletListItem(int) // * List item
  | NumberedListItem(int) // . List item
  | Label(string) // [label]:
  | SubstitutionDef(string) // :name: value
  | Hyperlink(string) // [text](address)
  | OpenBlockDelimiter // --
  | CodeBlockDelimiter // ----
  | ExampleBlockDelimiter // ====
  | QuoteBlockDelimiter // ____
  | SidebarBlockDelimiter // ****
  | BlockTitle // .Block title
  | SubstitutionUse(string) // {name}

let consumeBlockTitle = line => {
  let blockTitleLine = %re("/^\.([^\s].*)$/")
  switch blockTitleLine->getMatches(line) {
  | [_, title] =>
    Js.log("BLOCKTITLE: " ++ title)
    [BlockTitle, Text(title)]
  | _ => []
  }
}

let consumeHeading = line => {
  let titleLine = %re("/^(=+)\s+([^\s].*)$/")
  switch titleLine->getMatches(line) {
  | [_, signs, title] =>
    let level = signs->String.length
    Js.log("HEADING(level " ++ level->string_of_int ++ "): " ++ title)
    [Heading(level), Text(title)]
  | _ => []
  }
}

let consumeSubstitution = line => {
  let pattern = `^:([${alpha}][_${alnum}]*(\\.[_${alnum}]+)*):\\s+(.*)\$`
  let substLine = Js.Re.fromString(pattern)
  switch substLine->getMatches(line) {
  | [_, name, _, value] =>
    Js.log(`SUBST: ${name} --> ${value}`)
    [SubstitutionDef(name), Text(value)]
  | _ => []
  }
}

let consumeAttribute = line => {
  let attrLine = %re("/^\[\s*([^\[\]]*)\]$/")
  switch attrLine->getMatches(line) {
  | [_, attributes] =>
    Js.log("ATTR: " ++ attributes)
    [Attribute(attributes)]
  | _ => []
  }
}

let consumeHyperlink = line => {
  let hlinkLine = %re("/\[\s*([^\]]*)\]\(\s*([^\s\)]*)\s*\)/")
  switch hlinkLine->getMatches(line) {
  | [_, text, link] =>
    Js.log(`LINK: <${link}> with text: '${text}'`)
    [Hyperlink(link), Text(text)] // do NOT merge text token with the next
  | _ => []
  }
}

let consumeLabel = line => {
  let labelLine = %re("/^\[\s*([^\]]+)\]:\s*$/")
  switch labelLine->getMatches(line) {
  | [_, label] =>
    Js.log(`LABEL: ${label}`)
    [Label(label)]
  | _ => []
  }
}

let consumeBulletListItem = line => {
  let itemLine = %re("/^\s*([*]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [_, stars, text] =>
    let level = stars->String.length
    Js.log(`LIST: bullet level ${level->string_of_int} with text: '${text}'`)

    [BulletListItem(level), Text(text)]
  | _ => []
  }
}

let consumeNumberedListItem = line => {
  let itemLine = %re("/^\s*([.]+)\s+(.*)$/")
  switch itemLine->getMatches(line) {
  | [_, dots, text] =>
    let level = dots->String.length
    Js.log(`LIST: item level ${level->string_of_int} with text: '${text}'`)
    [NumberedListItem(level), Text(text)]
  | _ => []
  }
}

let consumeRegularLine = line => {
  let chara = Js.String.charAt(0, line)
  let tok = switch chara {
  | "[" => consumeHyperlink(line)
  | "*" => consumeBulletListItem(line)
  | "." => consumeNumberedListItem(line)
  | _ => []
  }
  if tok == [] {
    Js.log("TEXT: " ++ line)
    [Text(line)]
  } else {
    tok
  }
}

exception EndOfBlock(string)

let rec consumeRegularBlock = (name, delimiter, line, lnum, subs, attrs) => {
  if line == delimiter {
    Js.log(`BLOCK: ${name} with attributes [${attrs}]`)
    let rec promi = ((initial, lnum, subs, attrs)) =>
      if initial {
        consumeInitialLine(lnum, subs, attrs, delimiter)
      } else {
        consumeLine(lnum, subs, attrs, delimiter)
      }
      ->then(promi)
      ->catch(err =>
        switch err {
        | EndOfBlock(_) =>
          Js.log(`BLOCK: ${name} ended at line ${string_of_int(lnum)}`)
          resolve((lnum + 1, subs, attrs))
        | EndOfFile(_) =>
          Js.log(`WARNING: ${name} block not closed`)
          reject(err)
        | _ =>
          Js.log("WARNING: Unexpected error")
          reject(err)
        }
      )
    promi((true, lnum, subs, attrs))
  } else {
    resolve((lnum, subs, attrs))
  }
}
and consumeInitialLine = (lnum, subs, attrs, delimiter) => {
  nextLine(lnum)->then(((line, lnum)) => {
    if line == "" {
      resolve((true, lnum, subs, attrs))
    } else if attrs == "" && line == delimiter {
      reject(EndOfBlock(delimiter))
    } else {
      let chara = Js.String.charAt(0, line)
      switch chara {
      | "." =>
        let consumed = consumeBlockTitle(line)
        if consumed != [] {
          resolve((true, lnum, subs, ""))
        } else {
          let _ = consumeRegularLine(line)
          resolve((false, lnum, subs, ""))
        }
      | "=" =>
        let consumed = consumeHeading(line)
        if consumed != [] {
          resolve((true, lnum, subs, ""))
        } else {
          consumeRegularBlock("Example", "====", line, lnum, subs, attrs)->then(((
            next,
            subs,
            _,
          )) => {
            if next == lnum {
              // No example block was consumed
              let _ = consumeRegularLine(line)
            }
            resolve((next != lnum, next, subs, ""))
          })
        }
      | ":" =>
        let consumed = consumeSubstitution(line)
        switch consumed {
        | [SubstitutionDef(name), Text(value)] =>
          let subs = subs->List.add((name, value))
          resolve((true, lnum, subs, ""))
        | m =>
          assert (m == [])
          let _ = consumeRegularLine(line)
          resolve((false, lnum, subs, ""))
        }
      | "[" =>
        let consumed = consumeAttribute(line)
        switch consumed {
        | [Attribute(attributes)] => resolve((true, lnum, subs, attributes))
        | m =>
          assert (m == [])
          let consumed = consumeLabel(line)
          if consumed != [] {
            resolve((true, lnum, subs, ""))
          } else {
            let _ = consumeRegularLine(line)
            resolve((false, lnum, subs, ""))
          }
        }
      | "_" =>
        consumeRegularBlock("Quote", "____", line, lnum, subs, attrs)->then(((next, subs, _)) => {
          if next == lnum {
            // No quote block was consumed
            let _ = consumeRegularLine(line)
          }
          resolve((next != lnum, next, subs, ""))
        })
      | "*" =>
        consumeRegularBlock("Sidebar", "****", line, lnum, subs, attrs)->then(((next, subs, _)) => {
          if next == lnum {
            // No sidebar block was consumed
            let _ = consumeRegularLine(line)
          }
          resolve((next != lnum, next, subs, ""))
        })
      | _ =>
        let _ = consumeRegularLine(line)
        resolve((false, lnum, subs, ""))
      }
    }
  })
}
and consumeLine = (lnum, subs, attrs, delimiter) => {
  nextLine(lnum)->then(((line, lnum)) => {
    if line == "" {
      Js.log("<empty>")
      resolve((true, lnum, subs, attrs))
    } else if attrs == "" && line == delimiter {
      reject(EndOfBlock(delimiter))
    } else {
      let chara = Js.String.charAt(0, line)
      switch chara {
      | "[" =>
        let consumed = consumeAttribute(line)
        switch consumed {
        | [Attribute(attributes)] => resolve((true, lnum, subs, attributes))
        | m =>
          assert (m == []) // Appease the compiler
          let _ = consumeRegularLine(line)
          resolve((false, lnum, subs, ""))
        }
      | _ =>
        let _ = consumeRegularLine(line)
        resolve((false, lnum, subs, ""))
      }
    }
  })
}

let subs = list{}
let attrs = ""
let lnum = 0

let rec promi = ((initial, lnum, subs, attrs)) =>
  if initial {
    consumeInitialLine(lnum, subs, attrs, "")
  } else {
    consumeLine(lnum, subs, attrs, "")
  }
  ->catch(err =>
    switch err {
    | EndOfFile(_) =>
      Js.log("DONE")
      reject(err)
    | _ =>
      Js.log("Unexpected error")
      reject(err)
    }
  )
  ->then(promi)
  ->catch(_ => {
    resolve()
  })
promi((true, lnum, subs, attrs))->ignore