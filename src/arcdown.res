open Belt

let backtick = "`"

let source = `
[NOTE]
====
This is how to start a new example
block within this block:

.Nested block
[example]
====
A small example
====
====
`

open Promise

let lines = "\n"->Js.String.split(source)

exception EndOfFile(string)
let nextLine = lnum =>
  switch lines[lnum] {
  | Some(line) => resolve((line, lnum + 1))
  | None => reject(EndOfFile("EOF"))
  }

type state = {
  lnum: int,
  attrs: string,
  subs: list<(string, string)>,
}

let alpha = "A-Za-z"
let alnum = "0-9" ++ alpha

let getMatches = (regex, someline) =>
  switch regex->Js.Re.exec_(someline) {
  | Some(result) =>
    Js.Re.captures(result)->Array.map(x => Js.Nullable.toOption(x)->Option.getWithDefault(_, ""))
  | None => []
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

let consumeNormalLine = (line, _, _) => {
  Js.log("TEXT: " ++ line)
}

exception EndOfBlock(string)
let rec consumeExampleBlock = (line, lnum, subs, attrs) => {
  let blockLine = %re("/^====\s*$/")
  switch blockLine->getMatches(line) {
  | [_] =>
    Js.log("BLOCK: Example with attributes: " ++ attrs)
    let checkEndBlock = (ln, attrs) => {
      attrs == "" && blockLine->getMatches(ln)->Array.length != 0
    }
    let rec promi = ((lnum, subs, attrs)) =>
      consumeLine(lnum, subs, attrs, "=", checkEndBlock)
      ->then(promi)
      ->catch(err =>
        switch err {
        | EndOfBlock(_) =>
          Js.log("BLOCK: Example ended at line " ++ string_of_int(lnum))
          resolve((lnum + 1, subs, attrs))
        | EndOfFile(_) =>
          Js.log("WARNING: Example block not closed")
          reject(err)
        | _ =>
          Js.log("WARNING: Unexpected error")
          reject(err)
        }
      )
    promi((lnum, subs, attrs))
  | _ => resolve((lnum, subs, attrs))
  }
}
and consumeLine = (lnum, subs, attrs, endchar, confirm) => {
  let firstChar = %re("/^./")
  nextLine(lnum)->then(((line, lnum)) => {
    let m = firstChar->getMatches(line)
    switch m {
    | [chara] =>
      if endchar == chara && confirm(line, attrs) {
        reject(EndOfBlock("example"))
      } else {
        switch chara {
        | "=" =>
          Js.log("Maybe a title")
          let (consumed, newsubs) = consumeTitle(line, subs)
          if consumed {
            resolve((lnum, newsubs, ""))
          } else {
            consumeExampleBlock(line, lnum, subs, attrs)->then(((next, subs, attrs)) =>
              if next > lnum {
                resolve((next, subs, ""))
              } else {
                consumeNormalLine(line, subs, attrs)
                resolve((lnum, subs, ""))
              }
            )
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
            consumeNormalLine(line, subs, attrs)
            resolve((lnum, subs, ""))
          }
        | _ =>
          Js.log("Something else")
          resolve((lnum, subs, "")) // TODO: preserve attributes for blank line
        }
      }
    | [] =>
      Js.log("<empty>")
      resolve((lnum, subs, attrs))
    | _ =>
      Js.log("Unexpected! " ++ Array.length(m)->string_of_int)
      resolve((lnum, subs, ""))
    }
  })
}

let subs = list{}
let attrs = ""
let lnum = 0

let rec promi = ((lnum, subs, attrs)) =>
  consumeLine(lnum, subs, attrs, "$", (_, _) => false)
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