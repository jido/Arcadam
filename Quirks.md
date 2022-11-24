# Quirks and differences

Although the Arcdown syntax is superficially very similar to AsciiDoc with Markdown links, there are some important differences.

## Indented code block

The first striking difference is the way indented text is handled in Arcdown.

The rule is:

> *If an indented block follows an indented code block with same indent, then it is treated as a normal paragraph.*

Let us go through this.

* Indented code block: it can be a delimited or a non-delimited code block and must not start like a list item
* Same indent: the indent of a code block is decided by its first line (the delimiter line if the block is delimited),
the indent of a paragraph must be the same throughout
* Follows: a non-delimited code block ends with an empty line or a non-indented line, since we are talking about an 
indented block the paragraph must be after an empty line in this case.
For a delimited block it must be after the end delimiter or an empty line

### More notes:

Arcdown commands, such as attribute line, substitution definition, block title and comments count as empty lines.

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
The document writer probably intended to include the non-indented line in the code block but the intended end block delimiter becomes a start block delimiter.

Hopefully that issue is easy to spot.

```
  A code block
  
  A normal paragraph
    This is another code block
```

Since all lines in an indented paragraph must have the same indent, the increased (or decreased) indent means that the next line is a code block.

Note that if that was a code block, the second line would still be part of the code block.

```
  . Item in a numbered list
  continued on the next line
```

If the first indented line is a list item (starts with dots, stars or contains ":: ") then it is treated as an indented paragraph.

## Tables

Arcdown does not support all the table formatting options of AsciiDoc. 

The only supported format letter is "h" (header row or column).

Horizontal alignment can only be set at column level or on a horizontally merged cell (see below). It does not apply to header rows. 

Vertical alignment can only be set at row level or on a vertically merged cell (see below). It does not apply to header columns. 

Use the [rows] attribute to format rows, like the [cols] attribute for columns. 

Use "5*|" to repeat a cell 5 times horizontally. With a dot in front, it is repeated vertically or it can repeat in both directions with "5.3*|".

Use "5+|" to merge 5 cells horizontally. With a dot in front, cells are merged vertically or both can be combined with "5.3+|".

The content alignment of a merged cell can be set at the same time. Alignment symbols must follow the same pattern as the cell numbers, for example "2+<|" or ".4+.^|" or "5.3+>.>|".

If a cell starts without a space between "|" and the content then it is not interpreted and the repeat/merge instructions for next cell will not work if they are on the same line. 
