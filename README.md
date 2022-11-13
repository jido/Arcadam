![logo](Arcdown%20logo.png)
# Arcdown

A lightweight markup language to format documents using plain text

## Syntax

The syntax of Arcdown is heavily inspired by AsciiDoc and by Markdown.

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

```
= Document title
:authors: Author Name <author@email.org>
:version: v2.0, 2019-03-22
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

### Text Formatting

```
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

```
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

Page break (does not appear if the output is a HTML document):

```
<<<
```

### Hyperlinks

```
[#anchor]:
Part 1: This text is selected by the anchor.

[Go to Part 1](#anchor)

[Go to Products page on this site](/Products.html)

[Go to Offers page in current path](Offers.html)

[Go to an arbitrary webpage](https://www.github.com)
```

The text inside square brackets becomes a hyperlink which loads the content
specified in the round brackets.

When the output format allows it, footnotes are also hyperlinks.

Example:

```
There are contractual implications to this statement.[^terms]

[^terms]:
Please refer to our [Terms and Conditions page](TandC.html) for more information.
```

### Inline Content

* To insert an image or a multimedia file, use a hyperlink with "!" in front

The hyperlink text will be used as the "alt" label.

Double the "!" to make the image in line with the text rather than in a new block.

Example:

```
![Arcdown logo](Arcdown-logo.png)

The Github mascot: !![image](octocat.jpg)
```

* To insert the contents of another Arcdown file, use the "include" attribute

It should come before a hyperlink with the location of the file. Note that 
for security reasons, including a file from an arbitrary location is disabled 
by default.

The file contents are inserted at the location of the include.

The hyperlink text can be used to specify a tag so only the tagged region of 
the Arcdown file is included.

Example:

```
[include]
[region](Tagged-file.arcd)
```

A tagged region is defined using begin and end labels:

```
[begin region]:
This text can be included
on its own

[end region]:
----
Inside a delimited code block, the tagged
  // ---- begin::coderegion ----
region is defined using begin:: and end:: between
code block markers at the end of a code line.
  // ---- end::coderegion ----
----
```

### Lists

```
. Number one
. Number two
. Number three

* First bullet
* Second bullet
* Third bullet

Item 1:: First description
Item 2:: Second description
Item 3:: Third description
```

A list that immediately follows an item from another list is automatically 
nested. Leading whitespace has no effect.

Ordered and unordered list markers can be repeated to indicate the level, 
just like [headers](#headers). Additional levels can be used in a 
description list by adding another ":" each time.

However the levels are not enforced so you could have a list level 1 (\*)
nested inside a list level 2 (\*\*). It is good style to match the marker
level with the nesting level of the list.

Example:

```
. This is number one
** It has two bullets
** This is the second bullet
. This is number two
  .. This is a sublist
  .. with three elements
  .. This is the third element
```

Use "+" to force a list item on multiple lines. If it is used on an empty 
line, that starts a new paragraph. Note that indented code blocks don't 
require a "+".

A line with an empty attribute "\[ ]" forces the next list item to start 
a new list instead of continuing the previous list or nesting inside it.

### Styled Blocks

Code blocks (monospaced):

```
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

```
|===
| Header 1 \
| Header 2 \
| Header 3

| Row 1 Column 1
| Row 1 Column 2
| Row 1 Column 3

| Row 2 Column 1
2+| Row 2 Merged columns 2 and 3
|===
```

All the headers must be on the same line, or "\\" must be used to escape the 
line breaks otherwise the table is generated without a header row.

An empty line indicates a new row but it is optional after second row (since
the generator knows the number of columns then).

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

### Escape character

The backslash "\\" is used to prevent the generator from interpreting the
following character specially.

See also [Text Formatting](#text-formatting) to prevent format markers from
being interpreted over a span of text using "+".

### Substitutions

Substitution values can be defined and reused.

Example:

```
:substitution: value to be inserted

Using the {substitution}

[{substitution}](/index.html)
```

### Attributes

An attribute is written inside square brackets and apply to the following paragraph or block.

Additional attributes can be applied using commas to separate them.

Example:

```
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
```

If the attribute starts with a dot "." and a stylesheet is defined, the specified style class is applied.

Some attributes, such as the style class attribute, can be used in the middle of the text by highlighting the part of the text they apply to.

Example:

```
This paragraph contains [.underline]#underlined
text inside#.
```

### Block Title

A block title starts with a dot "." on its own line. It comes before the attributes.

If the block title is used with an image, it is used as caption. 
Additionally, if the image caption contains a link then clicking 
on the image loads the (first) link.

Example:

```
.Fruit basket
,===
apples,oranges,pears
,===

.A mountain sunset on [Flickr](https://www.flickr.com/photos/javh/5448336655)
[size=200x100]
![Sunset](sunset.jpg)
```
