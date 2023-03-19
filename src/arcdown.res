open Belt

let backtick = "`"
let spaces = "      "
/*
let source = "
____
Quote text using
underscores
____

====
Example block used to
enclose an example
====
"

*/
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
  | Empty
  | Text(string)
  | Heading(int) // == Heading text
  | Attribute(string) // [attributes]
  | BulletListItem(int) // * List item
  | NumberedListItem(int) // . List item
  | Label(string) // [label]:
  | SubstitutionDef(string) // :name: value
  | Hyperlink(string) // [text](address)
  | FreeBlockDelimiter // --
  | CodeBlockDelimiter // ----
  | ExampleBlockDelimiter // ====
  | QuoteBlockDelimiter // ____
  | SidebarBlockDelimiter // ****
  | BlockTitle(string) // .Block title
  | SubstitutionUse(string) // {name}

let consumeBlockTitle = line => {
  let blockTitleLine = %re("/^\.([^\s].*)$/")
  switch blockTitleLine->getMatches(line) {
  | [_, title] =>
    Js.log("BLOCKTITLE: " ++ title)
    [BlockTitle(title)]
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

let consumeBlockDelimiter = line =>
  switch line {
  | "" => [Empty]
  | "--" => [FreeBlockDelimiter]
  | "====" => [ExampleBlockDelimiter]
  | "____" => [QuoteBlockDelimiter]
  | "****" => [SidebarBlockDelimiter]
  | _ => []
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

exception EndOfBlock(array<token>)

/*
let rec consumeRegularBlock = (name, delimiter, line, lnum) => {
  if line == delimiter {
    //Js.log(`BLOCK: ${name} with attributes [${attrs}]`)
    let rec promi = ((tok, initial, lnum)) =>
      {
        let was_attribute = switch tok->List.fromArray->List.reverse->List.head {
        | Some(Attribute(_)) => true
        | _ => false
        }
        if initial {
          consumeInitialLine(tok, lnum, was_attribute, delimiter)
        } else {
          consumeLine(tok, lnum, was_attribute, delimiter)
        }
      }
      ->then(promi)
      ->catch(err =>
        switch err {
        | EndOfBlock(blocktokens) =>
          Js.log(`BLOCK: ${name} ended at line ${string_of_int(lnum)}`)
          resolve((blocktokens, lnum + 1))
        | EndOfFile(_) =>
          Js.log(`WARNING: ${name} block not closed`)
          reject(err)
        | _ =>
          Js.log("WARNING: Unexpected error")
          reject(err)
        }
      )
    promi(([], true, lnum))
  } else {
    resolve(([], lnum))
  }
}
and
*/
let consumeInitialLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum)) => {
    let tokens = consumeBlockDelimiter(line)
    if tokens->Array.length != 0 {
      resolve((tok->Array.concat(tokens), true, lnum))
    } else {
      let chara = Js.String.charAt(0, line)
      switch chara {
      | "." =>
        let tokens = consumeBlockTitle(line)
        switch tokens {
        | [BlockTitle(title)] => resolve((tok->Array.concat(tokens), true, lnum))
        | m =>
          assert (m == [])
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), false, lnum))
        }
      | "=" =>
        let tokens = consumeHeading(line)
        if tokens != [] {
          resolve((tok->Array.concat(tokens), false, lnum))
        } else {
          let tokens = consumeRegularLine(line)
          resolve((tok->Array.concat(tokens), false, lnum))
        }
      | ":" =>
        let tokens = consumeSubstitution(line)
        switch tokens {
        | [SubstitutionDef(name), Text(value)] =>
          //let subs = subs->List.add((name, value))
          resolve((tok->Array.concat(tokens), true, lnum))
        | m =>
          assert (m == [])
          resolve((consumeRegularLine(line), false, lnum))
        }
      | "[" =>
        let tokens = consumeAttribute(line)
        switch tokens {
        | [Attribute(attributes)] => resolve((tok->Array.concat(tokens), false, lnum))
        | m =>
          assert (m == [])
          let tokens = consumeLabel(line)
          if tokens != [] {
            resolve((tok->Array.concat(tokens), true, lnum))
          } else {
            let tokens = consumeRegularLine(line)
            resolve((tok->Array.concat(tokens), false, lnum))
          }
        }
      | _ =>
        let tokens = consumeRegularLine(line)
        resolve((tok->Array.concat(tokens), false, lnum))
      }
    }
  })
}

let consumeLine = (tok, lnum) => {
  nextLine(lnum)->then(((line, lnum)) => {
    let tokens = consumeBlockDelimiter(line)
    if tokens->Array.length != 0 {
      resolve((tok->Array.concat(tokens), true, lnum))
    } else {
      let tokens = consumeAttribute(line)
      switch tokens {
      | [Attribute(attributes)] => resolve((tok->Array.concat(tokens), false, lnum))
      | m =>
        assert (m == []) // Appease the compiler
        let tokens = consumeRegularLine(line)
        resolve((tok->Array.concat(tokens), false, lnum))
      }
    }
  })
}

let subs = list{}
let attrs = ""
let lnum = 0

exception Success(array<token>)

let rec promi = ((tok, initial, lnum)) =>
  if initial {
    consumeInitialLine(tok, lnum)
  } else {
    consumeLine(tok, lnum)
  }
  ->catch(event =>
    switch event {
    | EndOfFile(_) => reject(Success(tok))
    | _ => reject(event)
    }
  )
  ->catch(err =>
    switch err {
    | Success(tokens) =>
      tokens->Array.forEach(token => Js.log2("T: ", token))
      Js.log(`DONE ${tokens->Array.length->string_of_int}`)
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
promi(([], true, lnum))->ignore