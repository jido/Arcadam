# Quirks and differences

Although the Arcdown syntax is superficially very similar to AsciiDoc with Markdown links, there are some important differences.

## Indented code block

The first striking difference is the way indented text is handled in Arcdown.

The rule is:

> *If an indented block follows an indented code block with same indent, then it is treated as a normal paragraph.*

Let us go through this.

* Indented code block: it can be a delimited or a non-delimited code block and must not start like a list item
* Same indent: the indent of a code block is decided by its first line (the delimiter line if the block is delimited),
the paragraph must start with the same indent
* Follows: in case of a non-delimited code block the paragraph must be after an empty line.
For a delimited block it must be after the end delimiter or an empty line

### More notes:

Arcdown commands, such as attribute line, substitution definition, block title and comments count as empty lines (no indent).

```
    This code block indent
   reduces
  on each line

    This is a paragraph
```

As a code block indent is decided by the first line, the code block above is considered incorrectly formatted.
In the output all three lines will be at the same level.

For the next indented block to be a paragraph, it must match the indent of the first line.

```
  A code block
this is not part of the code block
```

Unlike AsciiDoc, all the lines of the code block must be indented. The second line above is a normal paragraph.

```
  ----
  Indented and delimited
  code block
it is missing an end delimiter
  ----
  Start of a new code block
```

This document is really broken. Because of the non-indented line, the code block ends early. 
The document writer probably intended to include the non-indented line in the code block but the intended end block delimiter becomes a start block delimiter instead.

Hopefully that issue is easy to spot for writers.

```
  A code block
  
  A normal paragraph
    with uneven indent
A new paragraph
```

All lines in an indented paragraph are expected to have the same indent, so this is considered incorrectly formatted.

A line with no indent after an indented line always starts a new paragraph, even if it follows a normal paragraph.

```
  . Item in a numbered list
  continued on the next line
```

If the first indented line is a list item (starts with dots, stars or contains ":: ") then it is treated as an indented paragraph and never as code.

## Tables

Arcdown does not support all the table formatting options of AsciiDoc. 

The only supported format letter is "h" (header row or column).

```
[cols="h,6*>",rows="h,^"]
|===
|| jan | feb | mar | apr | may | jun

| Quarter +
2022
3+^| Q1 3+^| Q2
| Km | 12.4 | 40.0 | 12.9 | 8.5 | 15.7 .3+.>| 38.8 (provisional)
| Fz | 44.9 | 3.14 | 101.0 | 86.6 | 66.3
| Tt | 6.2 | 6.9 | 5.6 | 10.1 | 4.4
|===
```

Horizontal alignment can only be set at column level or on a horizontally merged cell (see below). It does not apply to header rows. 

Vertical alignment can only be set at row level or on a vertically merged cell (see below). It does not apply to header columns. 

Use the [rows] attribute to format rows, like the [cols] attribute for columns. 

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

Unlike Asciidoc, the number of repeated characters in a block boundary is fixed (length 4) and cannot be increased.
AsciiDoc uses matched boundary lengths for block nesting.

Nesting of the same block is supported in Arcdown by adding an attribute in the line immediately before the start of the block.

The attributes for the default use of each kind of block are:

```
[division]
--

[example]
====

[sidebar]
****

[table]
|===

[comment]
////
```

Code blocks cannot nest inside each other and are not shown in the list above.

Example:

```
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
```

A block can start after different elements, but attributes must be last before the start of the block or they are ignored.

A block header could look like:

```
.Title
[#anchor]:
[:begin region]:
:substitution: value
[division]
--
```

The same applies to other elements like a paragraph, a list or a heading.

Note that a block title or a substitution is not recognised in the middle of a paragraph. 
It is recommended to always leave an empty line after the end of a paragraph.

A block boundary *without* an attribute in the line above can be either a block ending or the start of a non-nested block.
