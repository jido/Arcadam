![logo](Arcadam%20logo%20small.png)
# Arcadam

A lightweight markup language to format documents using plain text

## Syntax

The syntax of Arcadam is heavily inspired by AsciiDoc and by Markdown.

### Headers

```
= Document Title

== Level 1 Section Title

=== Level 2 Section Title...
```

Use "=" in front of the header, repeated as needed to increase the level.

There must be only one document title in the document. The document title may be followed immediately by an
optional document header which contains metadata related to the document, such 
as the authors or a marker for the generator to insert a table of contents.

Example:

```IDL
= Document title
:authors: Author Name <author@email.org>
:revision: v2.0, 2019-03-22
:toc:
```

### Paragraphs

A sequence of non-empty lines form a paragraph.

To force a line break in the middle of a paragraph, end the line with "+".

Example:

```
This is part of a single
paragraph spread over
multiple lines of text. +
Because of the line break, this goes on a separate line.
```

Paragraphs may be grouped in a free block by enclosing them with "--".

Example:

```
--
This is the first paragraph.

Another paragraph is added
to the block.
--
```

A paragraph must be followed by an empty line or an indented line. If the
paragraph is at the end of a block, then the empty or indented line can
come after the end block marker. In practice, that means it is better to
separate paragraphs with empty lines and always leave an empty line after
a block.

### Text Formatting

```asciidoc
This is *bold*

This is _italic_

This is `monospaced`

This is ^superscript^

This is ~subscript~

This is #highlighted#

This is +_normal text_ (no style)+
```

Styles can be combined. Any style can be used in the middle of a word by 
doubling the format markers, except for superscript and subscript which
don't require doubling.

Example:

```asciidoc
*_Combine bold and italic_*

the "it" is __it__alic

superscri^pt^ for "pt"
```

To enter text which contains format markers, enclose the text with "+" to prevent
the generator from interpreting them.

### Breaks

Horizontal line:

```
'''
```

Page break (not visible in the browser if the output is a HTML document):

```
<<<
```

Arcadam tries to break the text at a natural place between pages, like the end of a paragraph.
Add ">>>" at the end of the line to prevent this behaviour in a specific place.
That may force a page break in the middle of a paragraph.

### Hyperlinks

```markdown
[Go to Products page on this site](/Products.html)

[Go to Offers page in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)

[#anchor]:
Part 1: This text is selected by the anchor.

[Go to Part 1](#anchor)
```

The text inside square brackets becomes a hyperlink which loads the content
specified in the round brackets. If the round brackets are empty and the 
text matches a section title then the link goes to that section.

To make a hyperlink to a file generated by Arcadam replace the file extension
with an asterisk "\*". It will be automatically set to the file extension
associated with the output format.

When the output format allows it, footnotes [`^`] and bibliographic references
[`>`] are also hyperlinks.

Example:

```markdown
There are contractual implications to this statement.[^terms]

[^terms]:
Please refer to our Terms and Conditions [>T&C] for more information.
```

### Inline Content

```markdown
.sample image
!![Arcadam logo](Arcadam-logo.png)

The Github mascot: ![image](octocat.jpg)
```

Use "!" in front of a hyperlink to insert an image or a multimedia file.
Double the "!" to put the image in a new block rather than in line with the text.

The hyperlink text will be used as the "alt" label in HTML.

Captions are set using a [Block Title](#block-title).

See also [Include](#include).

### Lists

```IDL
1. Number one
. Number two
. Number three

* First bullet
* Second bullet
* Third bullet

Item 1:: First description
Item 2:: Second description
Item 3:: Third description
```

Number 1 for the first item is optional and no other number is permitted.
A list that immediately follows an item from another list is automatically 
nested. Leading whitespace has no effect.

Ordered and unordered list markers can be repeated to indicate the level, 
just like [headers](#headers). Additional levels can be used in a 
description list by adding another ":" each time.

However these levels are not enforced so there could be a list level 1 (`*`)
nested inside a list level 2 (`**`). It is good style to match the marker
level with the nesting level of the list.

Example:

```
1. This is number one
** It has two bullets
** This is the second bullet
. This is number two
  .. This is a sublist
  .. with three elements
  .. This is the third element

[list]
. The list attribute forces a
new list to start up
```

Use "+" to force a list item on multiple lines. If it is used on an empty 
line, that starts a new paragraph inside the list item.

### Styled Blocks

Code blocks (monospaced):

```
  Indented text without
  line breaks is added 
  to a code block
  
  Normal text after a code block
  
  A second code block
  starts here

----
Another way to create
a code block delimited
with "----"
----

  ----
  A delimited code block
  can also be indented.
  
  It allows empty lines
  ----
```

Other blocks:

```
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
```

### Tables

```IDL
|===
| Header 1 \
| Header 2 \
| Header 3

| Row 1 Column 1 | Row 1 Column 2
| Row 1 Column 3

| Row 2 Column 1
2+| Row 2 Merged columns 2, 3
|===
```

All the headers must be on the same line, or "\\" must be used to escape the 
line breaks otherwise the table is generated without a header row.

Each new row should start on a new line. An empty line before a new cell 
marks the beginning of the second table row.

Arcadam markup can be used inside a table cell.
When the contents of a cell are written on multiple lines then the start of 
next cell must be in a normal paragraph or on a new line.
If there is no space between "|" and the text that follows, the generator doesn't 
interpret the contents of the cell until another "|" or the end of the line.

Other table styles:

```
,===
Header 1,Header 2,Header 3

Row 1 Column 1,Row 1 Column 2,Row 1 Column 3
Row 2 Column 1,Row 2 Column 2,Row 2 Column 3
,===
```

```
:===
Header 1:Header 2:Header 3

Row 1 Column 1:Row 1 Column 2:Row 1 Column 3
Row 2 Column 1:Row 2 Column 2:Row 2 Column 3
:===
```

### Forms

```
[form]
====
[input,value="Default contents"]
Field label

[checkbox]
|+| Checkbox description
| | Unchecked checkbox

[options,value="choice 2"]
* choice 1
* choice 2
* choice 3

.Picker label
[picker]
Any valid Arcadam content
====
```

A form layout has two columns, one for labels and one for form elements.
An input field label or a picker label appears in the first column while
a checkbox description or text for an option appears in the second column.

All form elements can have a value. If an element also has an id, then a
substitution is defined from the id of the element to its value. In case
of a checkbox, the substitution is only defined when the checkbox is 
checked. Most symbols can be used to check it.

### Tabs

```
[tabset]
--
[tablist,id=maintab,value=Products]
* Products
* Portfolio
* Contact

[tab,on="maintab:Products"]
****
This is the products tab
****

[tab,on="maintab:Portfolio"]
****
This is the portfolio tab
****

[tab,on="maintab:Contact"]
****
This is the contact tab
****
--
```

If a block title is defined for a tab then that replaces the item in the 
tablist for the tab title.

When the output format allows user interaction then the chosen tab is
displayed and other tabs display only their titles. Tabset content that
is not a tab is not displayed.

In other cases, the generator outputs all the tabs in the tab list as
well as tabset content. That is useful to insert page breaks between
tabs. The tablist is always hidden.

To enable user interaction a tablist must be defined and the "on" 
attribute must be set for each tab. The values in the tablist
cannot contain spaces. A numbered list can be used instead of a bullet 
list to select the tab by a number, or a description list to select it by
a term. The tablist "value" attribute defines the initial tab selection.

### Mathematical Notation

```
.Proof for [this triangle](http://www.cut-the-knot.org/pythagoras/proof31.gif) \
where {`a}, {`b} and {`c} are the side lengths. 
`===
// Comments, references and callouts are allowed
` msup(\( a + b \) / 2) ` = ` msup(c 2) + 4 ⋅ \( mfrac(1 / 2) a b \)

` msup(a 2) + 2 a b + msup(b 2) ` = ` msup(c 2) + 2 a b
` msup(a 2) + msup(b 2) ` = ` msup(c 2)
`===

`===
  y = (msup(x 2) " if " (x ≥ 1) " and " 2 " otherwise.")
`===
```

The mathematical notation uses a human-readable form of MathML. Note 
that MathML requires the typing of Unicode characters to write complex 
formulas.

The formulas can be aligned in a table-like matrix using the backtick
"`" as cell separator. Spaces are required.

### Block Title

```markdown
.Fruit basket
,===
apples,oranges,pears
,===

.A mountain sunset on [Flickr](https://www.flickr.com/photos/javh/5448336655)
[width=200,height=100]
!![Sunset](sunset.jpg)
```

A block title starts with a dot "." on its own line. It comes before the
attributes.

If a block title is added to a block image, it is used as caption. 
Additionally, if the image caption contains a link then clicking on the 
image loads the (first) link.

### Escape character

The backslash "\\" is used to prevent the generator from interpreting the
following character specially.

Example:

```
\* not a bullet list!
```

See also [Text Formatting](#text-formatting) to prevent format markers from
being interpreted over a span of text using "+".

### Substitutions

```IDL
:substitution: value to be inserted
```

Once defined, substitution values can be reused anywhere.

Example:

```markdown
Using the {substitution}

[{substitution}](/index.html)
```

### Attributes

An attribute is written inside square brackets and applies to the immediate following paragraph or block.

Additional attributes can be applied using commas to separate them.

Example:

```XML
[code=xml,.extract]
  <root>
    <element>
      This is XML text which 
      can be colourized
    </element>

[NOTE]
====
This is important.
====
```

Some attributes can take a value. If the value contains any special characters it should be enclosed in double quotes.

Example:

```
[rows=">h,^,^"]
```

If the attribute name starts with a dot "." and a stylesheet is defined then the specified style class is applied.

Some attributes, such as a style class attribute, can be used in the middle of text by highlighting the part of the text they apply to.

Example:

```
This paragraph contains [.underline]#underlined
text inside#.
```

### Include

```markdown
[include]
[region](Shared-file.arcd)
```

Use the "include" attribute to substitute the hyperlink with the contents 
of an Arcadam file found at the specified location.

The hyperlink text may be used to provide a tag name so only the designated 
region of the Arcadam file is inserted instead of the whole contents.

Note that for security reasons, including a file from an arbitrary location 
is disabled by default.

### Tags

The begin and end tags define a named region for include:

```C
[:begin region]:
This text can be included
on its own
[:end region]:

----
Inside a code block, a named region
  // begin::coderegion ----
is defined using begin:: and end:: 
tags before a code block marker that 
  // end::coderegion ----
ends the line.
----
```

### Callouts

```Eiffel
[code=ruby]
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
```

For automatic callout numbering use `:()` instead of numbers.

When it encounters callouts in a code block, the generator inserts 
the callout symbols in the line above and the entire line which 
contains callouts is deleted.

If the deleted line starts with a known block comment marker, the 
generator looks for a matched closing comment marker at the 
beginning of next line and deletes that too, for example `/*` and 
the closing comment marker `*/` in C.

### Comments

```
// Line comment

////
Comment 
block
////
```

Comments are for information only.

### Localisation

Arcadam documents can be localised for an international audience.

Define the "translations" substitution to enable it:

```
:translations: cn en es fr jp kr ru
```

This tells the generator to look for translations in the listed
directories.

Localisation files contain the text to translate with
synchronisation marks `@` which serve as placeholders for
untranslatable text. These marks always appear at the start of 
a line.

The following are included in the translation:

* formatting
* in-line attributes
* hyperlinks and inline content
* labels (references, footnotes and anchors)
* callouts
* user-defined substitutions
* comments

By default, code and math blocks are excluded. To include a code block
use the "localize" attribute:

```c
[localize=Y]
----
This will be translated.
----

----
Use a localize:: tag inside a
// localize::Y+2 ----
code block to select n lines
below the tag to translate
----
```

Conversely, the attribute can be used to prevent the translation 
of text:

```
[localize=N]
This must not be translated.
```

If applied to an include, it prevents the generator from looking
for a matching localisation file. Instead, the include link is
added to the translation so that it can be customised for each 
locale.

### Transformation Steps

The generator applies the following steps in order to transform the
contents of the document:

> _localize_ - process includes and apply translations to the text (if
> enabled)
> 
> _specialchars_ - replace special characters with their corresponding 
> entities (`<`, `>` and `&` for HTML). This step also
> enables syntax highlighting in code blocks and MathML conversion in math blocks.
> 
> _callouts_ - process callouts and code tags
> 
> _format_ - apply inline text formatting
> 
> _substitute_ - replace references with substitution values
> 
> _symbols_ - replace sequences of characters with symbols, for example 
> replace `->` with →
> 
> _apply_ - apply the attributes on blocks and on inline text
> 
> _linebreaks_ - process the line break character `+`

The current style class controls which transformation steps are 
applied. For example, code blocks use the ".verbatim" style class 
which only does the _specialchars_ and _callouts_ transformations.

To choose which steps are applied for a particular style class, define
a special substitution called "steps" followed by the style class.

Example:

```IDL
:steps.formatted: substitute,format,symbols
```
