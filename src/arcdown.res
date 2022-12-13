open Belt

let backtick = "`"
let spaces = "      "

let source = `
[NOTE]
====
This is how to start a new example
block within this block:
${spaces}
.Nested block
[example]
====
A small example
====
====

[Go to Products page on this site](/Products.html)

[Go to Offers page in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)

[#anchor]:
Part 1: This text is selected by the anchor.

[Go to Part 1](#anchor)

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
    let trimEnd = %re("/(\s*[^\s]+)*\s*/")
    switch trimEnd->getMatches(line) {
    | [_, line] => resolve((line, lnum + 1))
    | _ => resolve(("", lnum + 1))
    }
  | None => reject(EndOfFile("EOF"))
  }

let consumeTitle = (line, subs) => {
  let titleLine = %re("/^=+\s+([^\s].*)/")
  switch titleLine->getMatches(line) {
  | [_, title] =>
    Js.log("TITLE: " ++ title)
    (true, subs)
  | _ => (false, subs)
  }
}

let consumeSubstitution = (line, lnum, subs) => {
  let pattern = `^:([${alpha}]+(\\.[_${alnum}]+)*):\\s*(.*)`
  let substLine = Js.Re.fromString(pattern)
  switch substLine->getMatches(line) {
  | [_, name, _, value] =>
    Js.log("SUBST: " ++ name ++ " --> " ++ value)
    (true, lnum, subs->List.add((name, value)))
  | _ => (false, lnum, subs)
  }
}

let consumeAttribute = (line, subs) => {
  let attrLine = %re("/^\[\s*([^\[\]]*)\]\s*$/")
  switch attrLine->getMatches(line) {
  | [_, attributes] => (true, subs, attributes)
  | _ => (false, subs, "")
  }
}

let consumeHyperlink = (line, _, _) => {
  let hlinkLine = %re("/\[\s*([^\]]*)\]\(\s*([^\s\)]*)\s*\)/")
  switch hlinkLine->getMatches(line) {
  | [_, text, link] => (true, text, link)
  | _ => (false, "", "")
  }
}

let consumeLabel = line => {
  let labelLine = %re("/^\[\s*([^\]]+)\]:\s*$/")
  switch labelLine->getMatches(line) {
  | [_, label] => (true, label)
  | _ => (false, "")
  }
}

let consumeNormalLine = (line, _, _) => {
  Js.log("TEXT: " ++ line)
}

exception EndOfBlock(string)

let rec consumeRegularBlock = (name, delimiter, line, lnum, subs, attrs) => {
  if line == delimiter {
    Js.log(`BLOCK: ${name} with attributes: ${attrs}`)
    let rec promi = ((lnum, subs, attrs)) =>
      consumeLine(lnum, subs, attrs, delimiter)
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
    promi((lnum, subs, attrs))
  } else {
    resolve((lnum, subs, attrs))
  }
}
and consumeLine = (lnum, subs, attrs, delimiter) => {
  //let firstChar = %re("/^./")
  nextLine(lnum)->then(((line, lnum)) => {
    if line == "" {
      Js.log("<empty>")
      resolve((lnum, subs, attrs))
    } else {
      let chara = Js.String.charAt(0, line)
      if attrs == "" && line == delimiter {
        reject(EndOfBlock(delimiter))
      } else {
        switch chara {
        | "=" =>
          Js.log("Maybe a title")
          let (consumed, newsubs) = consumeTitle(line, subs)
          if consumed {
            resolve((lnum, newsubs, ""))
          } else {
            consumeRegularBlock("Example", "====", line, lnum, subs, attrs)->then(((
              next,
              subs,
              attrs,
            )) => {
              if next == lnum {
                // No example block was consumed
                consumeNormalLine(line, subs, attrs)
              }
              resolve((next, subs, ""))
            })
          }
        | ":" =>
          Js.log("Maybe a substitution")
          let (consumed, next, newsubs) = consumeSubstitution(line, lnum, subs)
          if consumed {
            resolve((next, newsubs, ""))
          } else {
            consumeNormalLine(line, subs, attrs)
            resolve((lnum, subs, ""))
          }
        | "[" =>
          Js.log("Maybe an attribute")
          let (consumed, newsubs, attributes) = consumeAttribute(line, subs)
          if consumed {
            Js.log("ATTR: " ++ attributes)
            resolve((lnum, newsubs, attributes))
          } else {
            let (consumed, text, link) = consumeHyperlink(line, subs, attrs)
            if consumed {
              Js.log("LINK: <" ++ link ++ "> with text: '" ++ text ++ "' and attributes: " ++ attrs)
              resolve((lnum, subs, ""))
            } else {
              let (consumed, label) = consumeLabel(line)
              if consumed {
                Js.log("LABEL: " ++ label)
                resolve((lnum, subs, ""))
              } else {
                consumeNormalLine(line, subs, attrs)
                resolve((lnum, subs, ""))
              }
            }
          }
        | "_" =>
          Js.log("Maybe a quote block")
          consumeRegularBlock("Quote", "____", line, lnum, subs, attrs)->then(((
            next,
            subs,
            attrs,
          )) => {
            if next == lnum {
              // No quote block was consumed
              consumeNormalLine(line, subs, attrs)
            }
            resolve((next, subs, ""))
          })
        | "*" =>
          Js.log("Maybe a list item")
          consumeRegularBlock("Sidebar", "****", line, lnum, subs, attrs)->then(((
            next,
            subs,
            attrs,
          )) => {
            if next == lnum {
              // No sidebar block was consumed
              consumeNormalLine(line, subs, attrs)
            }
            resolve((next, subs, ""))
          })
        | _ =>
          Js.log("Something else")
          resolve((lnum, subs, ""))
        }
      }
    }
  })
}

let subs = list{}
let attrs = ""
let lnum = 0

let rec promi = ((lnum, subs, attrs)) =>
  consumeLine(lnum, subs, attrs, "")
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
promi((lnum, subs, attrs))->ignore