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

A notable difference with Markdown and AsciiDoc is the way indented text is handled.
The number of spaces doesn't have any effect in Arcadam.

The rule is:

> *If an indented block follows another indented block then it continues it*
> 
> *If an indented block follows a line which starts with ">" or "." then it is treated as a normal paragraph*
> 
> *If the line starts with anything else then an indented block is treated as a code block*

Any number of indented blocks after a line which doesn't start with ">" or "." are code blocks.

These two symbols are the indent and nesting signs respectively.
The lines that follow are expected to start with ">" or with spaces.

The indent sign can be used purely for aesthetic reasons (indent), or to indicate the nesting level after a nesting element.

List items and custom markers are nesting elements.

To tell the Arcadam processor that the next paragraph should be nested, use the indent sign:

```
* A bullet point

> This is part of the bullet point too!
```

Without the indent sign the paragraph would be outside the list (or it would become a code block if it had spaces in front).

All the indented lines that follow are at the same nesting level, unless a line uses an extra ">" after an nesting element.

The following are equivalent:

```
* A bullet point
> * a nested item
> > * more nesting
> > that is part of previous line
> >
> > > adding a paragraph to most
> > > nested item
> another line of the bullet point
```

```
* A bullet point
> * a nested item
  > * more nesting
    that is part of previous line

    > adding a paragraph to most
      nested item
> another line of the bullet point 
```

Note: since the last line doesn't start with spaces, its only nesting is due to the indent sign ">".

An alternative way to write the same is with the nesting sign ".":

```
* A bullet point
.
  * a nested item
..
    * more nesting -
    that is part of previous line
...
      adding a paragraph to most
      nested item
.
  another line of the bullet point
```

The two can be combined, but since indent signs can be used without adding to the nesting and nesting can happen without indent signs the number of them needed to achieve the same effect as nesting signs can vary.

Example:

```
A paragraph

> Just indenting no nesting
>
> * A list item
  > * nested list item
      1. inside list
    
>>  Part of the outside list item
```

### More notes:

```
    This code block indent
   reduces
  on each line
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
> ```
  Indented and delimited
  code block
it is missing an end delimiter
  ```
  Start of a paragraph
~~~

Note that only the opening delimiter of a code block can have an indent sign in front.

This document is really broken. Because of the non-indented line, the code block ends early. 
The document writer probably intended to include the non-indented line in the code block but the intended end block delimiter becomes the first line of an indented code block instead.

Hopefully the issue is easy to spot for writers.

```
> An indented paragraph
  
  A normal paragraph
    with uneven indent
A new paragraph
```

A line with no indent after an indented line always starts a new paragraph, even if it follows a normal paragraph.
There should be an empty line between the paragraphs.

```
1. Item in a numbered list
> continued on the next line

  Another paragraph attached

// Non-indented line
  That is a code block
```

A list item can contain multiple indented paragraphs or delimited code blocks.

Any non-indented line which doesn't start with ">" or "." unsets the nesting level, even a comment.

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

Nesting of the same block is supported in Arcadam using indents or by adding an attribute in the line immediately before the start of the block.

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

> = Using indent
  ====
  Another example
  ====

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

A block boundary of the same indent level *without* an attribute in the line above can be either a block ending or the start of a non-nested block.

## Empty element

The empty element {:empty} or {:drop}, is not a character. It is an empty value.
It can be used when some text is expected but you don't want to provide any.

It can be used to unset a replacement value:

```
:key:toc {:drop}
```

Or to add a list item without any text:

```
* {:empty}
```

## Text formatting

Unlike AsciiDoc, Arcadam does not require to enclose text with backtick and plus
to prevent the processor from interpreting the contents:

    `do *not* __mess__ with my code`

Enclosing with backtick is sufficient.

However loose format markers don't affect strict format markers which means text inside double "`" can be bold or italic.
The formatter ignores a single format marker enclosed with the same marker which is doubled, unless they touch in which
case a backslash escape \ must be used.

Example:

```markdown
``monospac~ed~ with *bold* and _italic_ words``

**there *are* bold asterisks in this text**

backtick monospaced: ``\```

++**asterisks** and +pluses\+++
```

The backslash is not interpreted inside strict monospaced or unstyled text markers.
Some more complex examples are:

    **A``B** `C` D``

In this case only "C" is monospaced since "A``B" is bold which makes a boundary around the two letters,
and the formatter works from left to right.

But "C" is enclosed with double backticks "``", so should the monospaced markers be ignored?
They would only be if the double backticks were used as format markers which is not the case here.

    ``+not `` *styled*+``

Although the formatter works from left to right, it applies strict formatting first—in this case
it is the "unstyled" formatting that comes first.
The double backtick inside the text is therefore not interpreted and the output contains `not `` *styled*` in monospaced format.

    +_x_\+ ^2^+

The underscores around "x" are preserved thanks to the "+" format markers, but so is the backslash.
The output contains the text: `_x_\ ²+`.
To preserve the middle plus instead, the two parts should be surrounded by separate pairs of "+":

    +_x_+\+ +^2^+

Note the backslash escape to separate the two plus signs.

    ``\`ls -l *| cut -d \\* -f1 \```

Here the middle part with "cut -d" is in bold.
Single backticks cannot be used to stop it because they are part of the text, but backslash escape
can be applied on the asterisk to prevent the bold formatting.
Alternatively you could use unstyled formatting since there is no "+" in the text:

    ``+`ls -l *| cut -d \* -f1 `+``

Last example:

    __``a `*b c` d``__
    __``a `*b c` d``__ More*

On the first line, the whole inside part has italic monospaced style applied.

On the second line the strict bold formatting is applied first.
The output contains `__``a `\` then `b c`\`` d``__ More` in bold.
Escape the final asterisk with `\*` to restore the original format.
