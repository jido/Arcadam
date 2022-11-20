open Belt

let backtick = "`"

let source = `
Arcdown
A lightweight markup language to format documents using plain text

Syntax
The syntax of Arcdown is heavily inspired by AsciiDoc and by Markdown.

Headers
= Document Title

== Level 1 Section Title

=== Level 2 Section Title...
Use "=" in front of the header, repeated as needed to increase the level.

There must be only one document title in the document. The document title may be followed immediately by an optional document header which contains metadata related to the document, such as the authors or a marker for the generator to insert a table of contents.

Example:

= Document title
:authors: Author Name <author@email.org>
:version: v2.0, 2019-03-22
:toc:
Paragraphs
A sequence of non-empty lines form a paragraph.

To force a line break in the middle of a paragraph, end the line with "+".

Example:

This is part of a single
paragraph spread over
multiple lines of text. +
Because of the line break, this goes on a separate line.
Paragraphs may be grouped in a free block by enclosing them with "--".

Example:

--
This is the first paragraph.

Another paragraph is added
to the block.
--
Text Formatting
This is *bold*

This is _italic_

This is ${backtick}monospaced${backtick}

This is ^superscript^

This is ~subscript~

This is #highlighted#

This is +_normal text_ (no style)+
Styles can be combined. Any style can be used in the middle of a word by doubling the format markers, except for superscript and subscript which don't require doubling.

Example:

*_Combine bold and italic_*

the "it" is __it__alic

superscri^pt^ for "pt"
To enter text which contains format markers, enclose the text with "+" to prevent the generator from interpreting them.

Breaks
Horizontal line:

'''
Page break (not visible in the browser if the output is a HTML document):

<<<
Hyperlinks
[Go to Products page on this site](/Products.html)

[Go to Offers page in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)

[#anchor]:
Part 1: This text is selected by the anchor.

[Go to Part 1](#anchor)
The text inside square brackets becomes a hyperlink which loads the content specified in the round brackets. If the round brackets are empty and the text matches a section title then the link goes to that section.

When the output format allows it, footnotes are also hyperlinks.

Example:

There are contractual implications to this statement.[^terms]

[^terms]:
Please refer to our [Terms and Conditions page](TandC.html) for more information.
Inline Content
.sample image
![Arcdown logo](Arcdown-logo.png)

The Github mascot: !![image](octocat.jpg)
Use "!" in front of a hyperlink to insert an image or a multimedia file. Double the "!" to make the image in line with the text rather than in a new block.

The hyperlink text will be used as the "alt" label in HTML.

Captions are set using a Block Title.

See also Include.

Lists
. Number one
. Number two
. Number three

* First bullet
* Second bullet
* Third bullet

Item 1:: First description
Item 2:: Second description
Item 3:: Third description
A list that immediately follows an item from another list is automatically nested. Leading whitespace has no effect.

Ordered and unordered list markers can be repeated to indicate the level, just like headers. Additional levels can be used in a description list by adding another ":" each time.

However these levels are not enforced so there could be a list level 1 (\*) nested inside a list level 2 (\*\*). It is good style to match the marker level with the nesting level of the list.

Example:

. This is number one
** It has two bullets
** This is the second bullet
. This is number two
  .. This is a sublist
  .. with three elements
  .. This is the third element
[]
. The empty attribute [] forces a
  new list to start up
Use "+" to force a list item on multiple lines. If it is used on an empty line, that starts a new paragraph. Note that indented code blocks don't require a "+".

Styled Blocks
Code blocks (monospaced):

  Indented text without
  line breaks is added
  to a code block

----
Another way to
create a code
block using "-"
----

  ----
  A delimited code block
  can also be indented.

  It allows empty lines
  ----
Other blocks:

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
Tables
|===
| Header 1 \
| Header 2 \
| Header 3

| Row 1 Column 1 | Row 1 Column 2
| Row 1 Column 3

| Row 2 Column 1
2+| Row 2 Merged columns 2, 3
|===
All the headers must be on the same line, or "\\" must be used to escape the line breaks otherwise the table is generated without a header row.

An empty line indicates a new row but it is optional after second row (since the generator knows the number of columns then, either from the header row or the first content row).

Other table styles:

,===
Header 1,Header 2,Header 3

Row 1 Column 1,Row 1 Column 2,Row 1 Column 3
Row 2 Column 1,Row 2 Column 2,Row 2 Column 3
,===
:===
Header 1:Header 2:Header 3

Row 1 Column 1:Row 1 Column 2:Row 1 Column 3
Row 2 Column 1:Row 2 Column 2:Row 2 Column 3
:===
Block Title
.Fruit basket
,===
apples,oranges,pears
,===

.A mountain sunset on [Flickr](https://www.flickr.com/photos/javh/5448336655)
[size=200x100]
![Sunset](sunset.jpg)
A block title starts with a dot "." on its own line. It comes before the attributes.

If the block title is used with an image, it is used as caption. Additionally, if the image caption contains a link then clicking on the image loads the (first) link.

Escape character
The backslash "\\" is used to prevent the generator from interpreting the following character specially.

Example:

\* not a bullet list!
See also Text Formatting to prevent format markers from being interpreted over a span of text using "+".

Substitutions
:substitution: value to be inserted
Once defined, substitution values can be reused anywhere.

Example:

Using the {substitution}

[{substitution}](/index.html)
Attributes
An attribute is written inside square brackets and applies to the following paragraph or block.

Additional attributes can be applied using commas to separate them.

Example:

[source,xml]
<root>
  <element>
    This is XML text which
    can be colourized
  </element>

[NOTE]
====
This is important.
====
If the attribute starts with a dot "." and a stylesheet is defined, the specified style class is applied.

Some attributes, such as the style class attribute, can be used in the middle of text by highlighting the part of the text they apply to.

Example:

This paragraph contains [.underline]#underlined
text inside#.
Include
[include]
[region](Shared-file.arcd)
Use the "include" attribute to substitute the hyperlink with the contents of an Arcdown file found at the specified location.

The hyperlink text may be used to provide a tag name so only the designated region of the Arcdown file is inserted instead of the whole contents.

Note that for security reasons, including a file from an arbitrary location is disabled by default.

Tags
The begin and end tags define a named region for include:

[:begin region]:
This text can be included
on its own

[:end region]:

----
Inside a code block, a named region is
  //-- begin::coderegion ----
defined using begin:: and end:: tags after
hyphens and before a code block marker
that ends the line.
  //-- end::coderegion ----
----
Callouts
[source,ruby]
----
require 'sinatra'
# :1 ----

get '/hi' do
  # :2 ----
  "Hello World!"
  # :3 ----
end
----
(1):: Library import
(2):: URL mapping
(3):: HTTP response body
Callouts are inserted in the line above and the entire line which contains the callouts is deleted.

If the deleted line starts with a known block comment marker, the generator looks for a matched closing comment marker at the beginning of next line and deletes that too. (like /* */ in C or <!-- --> in XML)

Comments
// Line comment

////
Comment
block
////
Comments are for information only.

Localisation
Arcdown documents can be localised for an international audience.

Define the "translations" substitution to enable it:

:translations: cn en es fr jp kr ru
This tells the generator to look for translations in the listed directories.

Localisation files contain the text to translate with synchronisation marks @ which serve as placeholders for untranslatable text. These marks always appear at the start of a line.

The following are included in the translation:

formatting
in-line attributes
hyperlinks and inline content
labels (footnotes and anchors)
callouts
user-defined substitutions
comments
By default, code blocks are excluded. To include a code block use the "localize" attribute:

[localize=Y]
----
This will be translated.
----
Similarly, the same attribute can be used to prevent the translation of text:

[localize=N]
This must not be translated.
If applied to an include, it prevents the generator from looking for a matching localisation file. Instead, the include link is added to the translation so that it can be customised for each locale.
`

let lines = "\n"->Js.String.split(source)

let firstChar = %re("/^./")

let isTitle = line => {
  let titleLine = %re("/=+\s+([^\s].*)/")
  line
  ->Option.flatMap(titleLine->Js.Re.exec_(_))
  ->Option.flatMap(result => Js.Re.captures(result)[1])
  ->Option.flatMap(Js.Nullable.toOption(_))
}

for lnum in 1 to Array.length(lines) {
  let line = lines[lnum - 1]
  let _ =
    line
    ->Option.flatMap(firstChar->Js.Re.exec_(_))
    ->Option.flatMap(result => Js.Re.captures(result)[0])
    ->Option.flatMap(Js.Nullable.toOption(_))
    ->Option.flatMap(chara =>
      switch chara {
      | "=" =>
        Js.log("Maybe a title")
        let _ = switch isTitle(line) {
        | Some(title) => Js.log("TITLE: " ++ title)
        | None => Js.log("unmatched " ++ line->Option.getWithDefault("n/a"))
        }
        None
      | ":" =>
        Js.log("Maybe a substitution")
        None
      | "[" =>
        Js.log("Maybe an attribute")
        None
      | _ =>
        Js.log("Something else")
        None
      }
    )
}