# Quirks and differences

Although Arcadam is superficially very similar to AsciiDoc with a Markdown-like syntax, there are some important differences.

## Links and macros

AsciiDoc can recognise a hyperlink as such; the text of the link is added after the URI in square brackets `[]`.

Arcadam prefers following the Markdown convention of putting the text of the link before the URI:

```
[This is the text to click](https://example.com)
```

Since macros, directives etc. of AsciiDoc rely on a link-like syntax a lot of features are written differently in Arcadam.

This table shows Arcadam syntax compared to AsciiDoc:

| feature                | linking it             | set target                             | AsciiDoctor |
|------------------------|------------------------|----------------------------------------|-------------|
| anchor                 | `[link text](#target)` | `[#target]:` or <br> `[id=target]` or `{#target}` | `<<target,link text>>` /<br> `[#target]` or `[[target]]` |
| heading link           | `[Title Text]()`       | `## Title Text`                        | `<<Title Text>>` / `== Title Text` |
| foot note              | `{^note-name}`         | `[^note-name]:` <br>  `note text`      | `footnote:[note text]` *(combined)* |
| bibliography reference | `{>reference}`         | `[>reference]:` <br> `contents` and <br> `[!bibliography]` where to put it | `<<reference>>` /<br> `[bibliography]` <br> `== References` then <br> `- [[[reference]]]` |
| index item             | `[!index]` where to put it           | `{+item}`                              | `[index]` <br> `== Index` / `((item))` |
| include region         | `[!include region](filepath)` | `{:begin region}` then <br> `{:end region}` | `include::filepath[tag=region]` /<br> `tag::region[]` then `end::region[]` |

AsciiDoc also has a link-like syntax for these, for example setting an anchor target can be written:

```
anchor:target[]
```

Markdown in Github flavour recently added footnotes with a syntax similar to Arcadam.
Most other features are not natively supported including setting a named anchor.
This is how to link to a heading in Markdown, which requires knowledge of how the anchor name is built:

```
[Title Text](#title-text)
```

## Indented code block

A notable difference with AsciiDoc is the way indented text is handled.

The rule is:

> *If an indented block follows another indented block then it is treated as a normal paragraph.*
> 
> *If an indented block follows a non-indented line then it is treated as a code block.*
> 
> *A list item is not treated as a normal paragraph or code block.*

List items are recognised by looking at the first line of the block.

Code blocks can be delimited or non-delimited. A non-delimited code block ends with an empty line.

A non-indented line should not follow immediately a code block or it will interrupt it.

### More notes:

Arcadam commands, such as attribute line, replacement value definition, block title and comments count as non-indented lines.

```
    This code block indent
   reduces
  on each line

    This is a paragraph
```

A code block indent is decided by the first line, so the code block above is considered incorrectly formatted.
In the output all three lines will be at the same level.

```
   A code block
no-indent text is not part of the code block
```

Unlike AsciiDoctor, all the lines of the code block must be indented. The second line above is a normal paragraph
and there should be an empty line before.

~~~
  ```
  Indented and delimited
  code block
it is missing an end delimiter
  ```
  Start of a new code block
~~~

This document is really broken. Because of the non-indented line, the code block ends early. 
The document writer probably intended to include the non-indented line in the code block but the intended end block delimiter becomes a start block delimiter instead.
In addition, an empty line is missing after the end delimiter.

Hopefully the issue is easy to spot for writers.

```
  A code block
  
  A normal paragraph
    with uneven indent
A new paragraph
```

All lines in an indented paragraph are expected to have the same indent, so this is considered incorrectly formatted.

A line with no indent after an indented line always starts a new paragraph, even if it follows a normal paragraph.
There should be an empty line between the paragraphs.

```
  . Item in a numbered list
  continued on the next line

  Another paragraph attached
+
  That is a code block
```

If the first indented line is a list item (starts with "1.", dots, stars or contains ":: ") then it is never treated as code.
A list item can contain multiple indented paragraphs or delimited code blocks.
It can also contain a non-delimited code block introduced with "+" on an empty line.

## Tables

Arcadam does not support all the table formatting options of AsciiDoc. 

The only supported format letter is "h" (header row or column).
If it is combined with other formatting "h" must be added after the alignment symbols.

```
[cols="h,6*>",rows="h,.^"]
|===
|| jan | feb | mar | apr | may | jun
|:::
| Quarter +
> 2022
3+^| Q1
3+^| Q2

| Km | 12.4 | 40.0 | 12.9 | 8.5 | 15.7 .3+.>| 38.8 (provisional)
| Fz | 44.9 | 3.14 | 101.0 | 86.6 | 66.3
| Tt | 6.2  | 6.9  | 5.6 | 10.1 | 4.4
|===
```

Horizontal alignment can only be set at column level or on a horizontally merged cell (see below). Header rows are not affected by column level alignment. 

Vertical alignment can only be set at row level or on a vertically merged cell (see below). Header columns are not affected by row level alignment.

Use the "rows" attribute to format rows, like the "cols" attribute for columns. 

Use "`5*|`" to repeat a cell 5 times horizontally.
With a dot in front, the cell is repeated vertically or it can repeat in both directions with "`5.3*|`".

Use "`5+|`" to merge 5 cells horizontally. 
With a dot in front, cells are merged vertically or both can be combined as in "`5.3+|`".

The merge span and the content alignment of a cell can be set at the same time. 
Alignment symbols must follow the same pattern as the cell numbers, for example "`2+<|`" or "`.4+.^|`" or "`5.3+>.>|`".

```
|not interpreted: 2+<| there is no merge in this cell
```

If the cell starts without a space between "`|`" and the content then it is not interpreted and the repeat/merge instructions that follow for next cell will not work. 

## Block boundaries

Unlike Asciidoc or Markdown, the number of repeated characters in a block boundary is fixed (length 4, 3 or 2) and cannot be increased.
Arcadam does not use matched boundary lengths for block nesting.

Nesting of the same block is supported in Arcadam by adding an attribute in the line immediately before the start of the block.

The attributes for the default use of each kind of block are:

```
[group]
--

[quoted]
___

[example]
====

[sidebar]
****

[table]
|===

[comment]
////
```

Code and content blocks cannot nest inside themselves and are not shown in the list above.

Example:

```
[NOTE]
====
This is how to start a new example 
block within this block:

= Nested block
[example]
====
A small example
====

in the note
====
```

A block can start after different elements, but attributes must be last before the start of the block or they are ignored.

A block header could look like:

```
= Title
[#anchor]:
:key:replacement value
[group]
--
```

The same applies to other elements like a paragraph, a list or a heading.

Note that header elements are not recognised in the middle of a paragraph. 
It is recommended to always leave an empty line after the end of a paragraph.

A block boundary *without* an attribute in the line above can be either a block ending or the start of a non-nested block.
