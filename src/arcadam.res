let loadSample = () => {
  let v = NodeJs.Fs.readFileSyncWith("sample.arcd", {encoding: "utf8"})
  v->NodeJs.Buffer.toString
}

open Promise

exception EndOfFile(string)
let lines = loadSample()->String.split("\n")

let nextLine = async (lnum, codeIndent) => {
  switch lines[lnum] {
  | Some(line) =>
    let count = Tokenizer.countSpaces(line)
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

let parseAttribute = (atext, attributes) => {
  let pattern = `^\\s*([.]?[${Tokenizer.alpha}]([.]?[${Tokenizer.alnum}])*)`
  let attrExpr = RegExp.fromString(pattern)
  switch attrExpr->Tokenizer.getMatches(atext) {
  | [name, _] =>
    Console.log2("Parse: attribute", name)
    attributes->Map.set(name, "")
  | k => Console.log2("Failed to parse:", k)
  }
}

let parseMarker = atext => {
  let pattern = `^\\s*([!-@\[-${Tokenizer.backtick}|~])\\s*(.*)`
  let markerExpr = RegExp.fromString(pattern)
  switch markerExpr->Tokenizer.getMatches(atext) {
  | [symbol, args] => Console.log4("Parse: marker prefix:", symbol, "rest:", args)
  | _ => Console.log2("Failed to parse:", atext)
  }
}

module type ParserOutput = {
  let outputHeading: (int, string) => unit
  let outputHyperlink: (string, string) => unit
  let startText: unit => unit
  let outputText: string => unit
  let endText: unit => unit
}

let doOutput = (tokens, module(Output: ParserOutput)) => {
  tokens->Option.forEach(token =>
    switch token {
    | Tokenizer.Text(value) =>
      Output.outputText(value)
      Output.endText()
    | Marker(marker) => parseMarker(marker)
    | _ => assert(false)
    }
  )
}

let parseDocument = (tok, module(Output: ParserOutput)) => {
  let _attributes = Map.make()
  let _replacements = Map.make()
  let final = tok->Array.reduce(None, (acc, token) =>
    switch token {
    | Tokenizer.Text(value) =>
      switch acc {
      | Some(Tokenizer.ReplacementKey(name)) =>
        //Console.log4("Parse: will replace reference", name, "with", value)
        _replacements->Map.set(name, value)
        None
      | Some(Hyperlink(target)) =>
        Output.outputHyperlink(target, value)
        Some(Text(""))
      | Some(Text(saved)) =>
        Output.outputText(saved)
        Some(token)
      | Some(Heading(level)) =>
        Output.outputHeading(level, value)
        None
      | Some(Marker(marker)) =>
        parseMarker(marker)
        Some(token)
      | Some(_) => assert(false)
      | None =>
        Output.startText()
        Some(token)
      }
    | Hyperlink(_)
    | Marker(_) =>
      switch acc {
      | Some(Text(saved)) => Output.outputText(saved)
      | Some(Marker(marker)) => parseMarker(marker)
      | None => Output.startText()
      | _ => assert(false)
      }
      Some(token)
    | Spaces(_) => acc
    | _ =>
      doOutput(acc, module(Output))
      switch token {
      | Attribute(attributeList) =>
        parseAttribute(attributeList, _attributes)
        None
      | ReplacementKey(_) => Some(token)
      | Heading(_) => Some(token)
      | _ => None
      }
    }
  )
  doOutput(final, module(Output))
  _replacements->Map.forEachWithKey((value, name) => Console.log4("Key:", name, "Value:", value))
}

let subs = list{}
let attrs = ""
let lnum = 0

exception Success(array<Tokenizer.token>)

let nextTokens = (lnum, codeIndent, tok) =>
  nextLine(lnum, codeIndent)->then(((line, lnum, codeIndent, nspaces)) =>
    resolve((line, lnum, codeIndent, nspaces, tok))
  )

let rec promi = ((tok, ltype, lnum)) =>
  switch ltype {
  | Tokenizer.Initial(codeIndent) =>
    nextTokens(lnum, codeIndent, tok)->then(Tokenizer.consumeInitialLine)
  | Following(codeIndent) => nextTokens(lnum, codeIndent, tok)->then(Tokenizer.consumeLine)
  | Code(codeIndent) => nextTokens(lnum, codeIndent, tok)->then(Tokenizer.consumeCodeLine)
  | Indented => nextTokens(lnum, true, tok)->then(Tokenizer.consumeIndentedCode)
  | List(codeIndent) => nextTokens(lnum, codeIndent, tok)->then(Tokenizer.consumeListLine)
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