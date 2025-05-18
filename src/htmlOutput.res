let outputHyperlink = (link, text) => {
  Console.log(`<a href="${link}">${text}</a>`)
}

let startText = () => {
  Console.log("<div>")
}

let endText = () => {
  Console.log("</div>")
}

let outputText = text => {
  Console.log(text)
}

let outputHeading = (level, text) => {
  Console.log(`<h${level->Int.toString}>${text}</h${level->Int.toString}>`)
}