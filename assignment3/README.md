Text Viewport Manager with Windowed Scrolling & Live Keyword Highlighter

A 16-bit 8088 assembly language program (NASM, DOS .COM format) that builds a text-mode viewer window directly in video memory (0xB800).

Features:
Clears the 80x25 screen and draws a double-line bordered viewport (rows 3-21, columns 8-72) with a centered title banner.
Streams a multi-line document into the window using LODSB / STOSW.
scroll_window_up scrolls only the text inside the window using MOVSW, leaving borders and the rest of the screen untouched.
find_and_highlight finds every occurrence of a keyword with REPE CMPSB and recolors only the attribute bytes, so the ASCII text is unchanged.
Status bar on row 23 shows the total match count, printed by a stack-based printNum routine.
