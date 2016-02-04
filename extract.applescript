-- From https://github.com/mgax/applescript-json
-- Copyright 2014-2016, Alex Morega
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
script json
  on encode(value)
    set type to class of value
    if type = integer or type = boolean then
      return value as text
    else if type = text then
      return encodeString(value)
    else if type = list then
      return encodeList(value)
    else if type = script then
      return value's toJson()
    else
      error "Unknown type " & type
    end if
  end encode


  on encodeList(value_list)
    set out_list to {}
    repeat with value in value_list
      copy encode(value) to end of out_list
    end repeat
    return "[" & join(out_list, ", ") & "]"
  end encodeList


  on encodeString(value)
    set rv to ""
    repeat with ch in value
      if id of ch = 34 then
        set quoted_ch to "\\\""
      else if id of ch = 92 then
        set quoted_ch to "\\\\"
      else if id of ch ³ 32 and id of ch < 127 then
        set quoted_ch to ch
      else
        set quoted_ch to "\\u" & hex4(id of ch)
      end if
      set rv to rv & quoted_ch
    end repeat
    return "\"" & rv & "\""
  end encodeString


  on join(value_list, delimiter)
    set original_delimiter to AppleScript's text item delimiters
    set AppleScript's text item delimiters to delimiter
    set rv to value_list as text
    set AppleScript's text item delimiters to original_delimiter
    return rv
  end join


  on hex4(n)
    set digit_list to "0123456789abcdef"
    set rv to ""
    repeat until length of rv = 4
      set digit to (n mod 16)
      set n to (n - digit) / 16 as integer
      set rv to (character (1 + digit) of digit_list) & rv
    end repeat
    return rv
  end hex4


  on createDictWith(item_pairs)
    set item_list to {}

    script Dict
      on setkv(key, value)
        copy {key, value} to end of item_list
      end setkv

      on toJson()
        set item_strings to {}
        repeat with kv in item_list
          set key_str to encodeString(item 1 of kv)
          set value_str to encode(item 2 of kv)
          copy key_str & ": " & value_str to end of item_strings
        end repeat
        return "{" & join(item_strings, ", ") & "}"
      end toJson
    end script

    repeat with pair in item_pairs
      Dict's setkv(item 1 of pair, item 2 of pair)
    end repeat

    return Dict
  end createDictWith


  on createDict()
    return createDictWith({})
  end createDict
end script

on run argv
  set inputPath to (item 1 of argv)
  set outputPath to (item 2 of argv)

  tell application "Keynote"
    set doc to open inputPath
    export doc to POSIX file (outputPath & "/yolover.pdf") as PDF with properties {export style:IndividualSlides}
    export doc to POSIX file (outputPath & "/yolover_notes.pdf") as PDF with properties {export style:SlideWithNotes}
    export doc to POSIX file (outputPath & "/build/images") as slide images with properties {image format:PNG}
    set slideData to {}
    repeat with theSlide in doc's slides
      set slideData to slideData & json's createDictWith({{"number", theSlide's slide number}, {"title", get (theSlide's default title item's object text)}, {"body", get (theSlide's default body item's object text)}, {"notes", get (theSlide's presenter notes)}})
    end repeat
  end tell

  set outputFile to open for access POSIX file (outputPath & "/build/extract.json") with write permission
  set eof of outputFile to 0
  write (json's encode(slideData)) to outputFile
  close access the outputFile
end run


