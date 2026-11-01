import re, os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib.utils import ImageReader
from reportlab.lib.enums import TA_CENTER
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                 Table, TableStyle, Preformatted, PageBreak, HRFlowable, Image)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.platypus.doctemplate import IndexingFlowable
from reportlab.pdfgen import canvas as canvas_module

BASE = r"C:\Users\Suraj\OneDrive\Desktop\mal4hackthon"
DOCS = os.path.join(BASE, "docs")
RENDERED = os.path.join(DOCS, "05-diagrams", "rendered")
OUT_DIR = os.path.join(DOCS, "09-architecture-deliverables")
os.makedirs(OUT_DIR, exist_ok=True)

PAGE_W, PAGE_H = A4
MARGIN = 20 * mm
HEADER_BAND = 13 * mm
FOOTER_BAND = 13 * mm
CONTENT_W = PAGE_W - 2 * MARGIN

NAVY = colors.HexColor('#0b2340')
NAVY_MED = colors.HexColor('#15385e')
GREY_TEXT = colors.HexColor('#555555')

NORMAL = ParagraphStyle('normal', fontName='Helvetica', fontSize=12, leading=15, spaceAfter=6)
H1 = ParagraphStyle('h1', fontName='Helvetica-Bold', fontSize=14, leading=18, spaceBefore=16, spaceAfter=8, textColor=NAVY)
H2 = ParagraphStyle('h2', fontName='Helvetica-Bold', fontSize=14, leading=17, spaceBefore=12, spaceAfter=6, textColor=NAVY_MED)
H3 = ParagraphStyle('h3', fontName='Helvetica-Bold', fontSize=14, leading=16, spaceBefore=8, spaceAfter=4, textColor=colors.HexColor('#2a4d73'))
META = ParagraphStyle('meta', fontName='Helvetica-Oblique', fontSize=12, leading=14, spaceAfter=3, textColor=GREY_TEXT)
BULLET = ParagraphStyle('bullet', parent=NORMAL, leftIndent=18, bulletIndent=6, spaceAfter=3)
QUOTE = ParagraphStyle('quote', parent=NORMAL, leftIndent=18, textColor=GREY_TEXT, fontName='Helvetica-Oblique')
CODE_SIZE = 8
CODE = ParagraphStyle('code', fontName='Courier', fontSize=CODE_SIZE, leading=10, spaceAfter=8, backColor=colors.HexColor('#f5f5f5'))
TBLHEAD = ParagraphStyle('tblhead', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=colors.white)
TBLCELL = ParagraphStyle('tblcell', fontName='Helvetica', fontSize=9, leading=11)
CAPTION = ParagraphStyle('caption', fontName='Helvetica-Oblique', fontSize=10, leading=12, alignment=TA_CENTER, spaceAfter=14, textColor=colors.HexColor('#333333'))
TITLE_STYLE = ParagraphStyle('titlebig', fontName='Helvetica-Bold', fontSize=22, leading=28, alignment=TA_CENTER, textColor=NAVY)
SUBTITLE = ParagraphStyle('subtitle', fontName='Helvetica', fontSize=14, leading=20, alignment=TA_CENTER, textColor=GREY_TEXT)
COVER_FIELD = ParagraphStyle('coverfield', fontName='Helvetica', fontSize=12, leading=18, alignment=TA_CENTER, textColor=colors.HexColor('#333333'))

INLINE_RE = re.compile(r'`([^`]+)`|\*\*([^*]+)\*\*|\[([^\]]+)\]\(([^)]+)\)')
FIG_RE = re.compile(r'\*\*Figure (\d+): ([^*]+)\*\*')
PATH_RE = re.compile(r'`([^`]+\.mmd)`')
CODE_MAX_CHARS = int((CONTENT_W - 12) / (CODE_SIZE * 0.6))

table_counter = [0]
bookmark_counter = [0]


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def inline(text):
    out, last = [], 0
    for m in INLINE_RE.finditer(text):
        out.append(esc(text[last:m.start()]))
        if m.group(1) is not None:
            out.append(f'<font face="Courier" size="12">{esc(m.group(1))}</font>')
        elif m.group(2) is not None:
            out.append(f'<b>{esc(m.group(2))}</b>')
        else:
            out.append(f'<u>{esc(m.group(3))}</u>')
        last = m.end()
    out.append(esc(text[last:]))
    return ''.join(out)


def wrap_code_lines(code_text):
    import textwrap
    out_lines = []
    for line in code_text.split('\n'):
        if len(line) <= CODE_MAX_CHARS:
            out_lines.append(line)
            continue
        indent_len = len(line) - len(line.lstrip(' '))
        indent = line[:indent_len]
        cont_indent = indent + '    '
        wrapped = textwrap.wrap(line.lstrip(' '), width=max(CODE_MAX_CHARS - indent_len, 20),
                                 break_long_words=False, break_on_hyphens=False,
                                 subsequent_indent=cont_indent, initial_indent=indent)
        out_lines.extend(wrapped if wrapped else [line])
    return '\n'.join(out_lines)


def is_table_sep(line):
    return bool(re.match(r'^\|?[\s:\-|]+\|?$', line)) and '-' in line


def parse_table_row(line):
    line = line.strip()
    if line.startswith('|'):
        line = line[1:]
    if line.endswith('|'):
        line = line[:-1]
    return [c.strip() for c in line.split('|')]


def build_table(rows):
    table_counter[0] += 1
    header = [Paragraph(inline(c), TBLHEAD) for c in rows[0]]
    body = [[Paragraph(inline(c), TBLCELL) for c in r] for r in rows[1:]]
    data = [header] + body
    ncols = len(header)
    colw = CONTENT_W / ncols
    t = Table(data, colWidths=[colw] * ncols, repeatRows=1)
    t.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.4, colors.grey),
        ('BACKGROUND', (0, 0), (-1, 0), NAVY),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f2f6fa')]),
    ]))
    cap = Paragraph(f'Table {table_counter[0]}', ParagraphStyle('tcap', fontName='Helvetica-Oblique', fontSize=9, textColor=colors.grey, spaceBefore=2, spaceAfter=8))
    return [t, cap]


def build_figures(line):
    fig_matches = list(FIG_RE.finditer(line))
    path_matches = list(PATH_RE.finditer(line))
    if not fig_matches or not path_matches:
        return None
    flows = []
    for i, fm in enumerate(fig_matches):
        num, cap = fm.group(1), fm.group(2).strip()
        if i >= len(path_matches):
            continue
        mmd_path = path_matches[i].group(1)
        basename = os.path.splitext(os.path.basename(mmd_path))[0]
        png_path = os.path.join(RENDERED, basename + '.png')
        if os.path.exists(png_path):
            ir = ImageReader(png_path)
            iw, ih = ir.getSize()
            max_w, max_h = CONTENT_W, 8.5 * inch
            scale = min(max_w / iw, max_h / ih, 1.0) if iw and ih else 1.0
            flows.append(Spacer(1, 6))
            flows.append(Image(png_path, width=iw * scale, height=ih * scale, hAlign='CENTER'))
            flows.append(Paragraph(f'<b>Figure {num}:</b> {inline(cap)}', CAPTION))
    tail_start = path_matches[min(len(fig_matches), len(path_matches)) - 1].end()
    tail = line[tail_start:].strip(' .').strip('()')
    if tail and len(tail) > 3:
        flows.append(Paragraph(inline(tail), QUOTE))
        flows.append(Spacer(1, 6))
    return flows


class Heading(IndexingFlowable):
    def __init__(self, text, level, style):
        IndexingFlowable.__init__(self)
        self.text, self.level, self.style = text, level, style
        self._bm = f'bm{bookmark_counter[0]}'
        bookmark_counter[0] += 1
        self._para = Paragraph(f'<a name="{self._bm}"/>' + text, style)

    def wrap(self, aw, ah):
        return self._para.wrap(aw, ah)

    def drawOn(self, canv, x, y, _sW=0):
        self._para.drawOn(canv, x, y, _sW)
        canv.bookmarkPage(self._bm)
        canv.addOutlineEntry(re.sub('<[^<]+?>', '', self.text), self._bm, self.level, closed=False)

    def notify(self, kind, stuff):
        pass


def parse_md(text):
    flow = []
    lines = text.split('\n')
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith('```'):
            i += 1
            code_lines = []
            while i < n and not lines[i].strip().startswith('```'):
                code_lines.append(lines[i]); i += 1
            i += 1
            flow.append(Preformatted(wrap_code_lines('\n'.join(code_lines)), CODE))
            continue

        fig_flows = build_figures(stripped) if ('Figure' in stripped and '.mmd' in stripped) else None
        if fig_flows:
            flow.extend(fig_flows)
            i += 1
            continue

        if stripped.startswith('|'):
            table_lines = []
            while i < n and lines[i].strip().startswith('|'):
                table_lines.append(lines[i].strip()); i += 1
            rows = [parse_table_row(l) for l in table_lines if not is_table_sep(l)]
            if rows:
                flow.extend(build_table(rows))
            continue

        if re.match(r'^#{1,4}\s', stripped):
            level = len(stripped.split(' ')[0])
            text_ = inline(stripped[level:].strip())
            style = H1 if level == 1 else (H2 if level == 2 else H3)
            flow.append(Heading(text_, min(level - 1, 2), style))
            i += 1
            continue

        if re.match(r'^(---+|\*\*\*+)$', stripped):
            flow.append(Spacer(1, 4)); flow.append(HRFlowable(width='100%', thickness=0.75, color=colors.grey)); flow.append(Spacer(1, 8))
            i += 1
            continue

        if stripped.startswith('> '):
            flow.append(Paragraph(inline(stripped[2:]), QUOTE)); i += 1; continue

        if re.match(r'^[-*]\s+', stripped):
            content = re.sub(r'^[-*]\s+', '', stripped)
            flow.append(Paragraph('&bull;&nbsp;&nbsp;' + inline(content), BULLET)); i += 1; continue

        if re.match(r'^\d+\.\s+', stripped):
            content = re.sub(r'^\d+\.\s+', '', stripped)
            flow.append(Paragraph(inline(content), BULLET)); i += 1; continue

        if stripped == '' or stripped.startswith('*End of'):
            i += 1; continue

        flow.append(Paragraph(inline(stripped), NORMAL)); i += 1

    return flow


def make_canvas_class(short_title, doc_id):
    class NumberedCanvas(canvas_module.Canvas):
        def __init__(self, *args, **kwargs):
            canvas_module.Canvas.__init__(self, *args, **kwargs)
            self._saved_page_states = []

        def showPage(self):
            self._saved_page_states.append(dict(self.__dict__))
            self._startPage()

        def save(self):
            total = len(self._saved_page_states)
            for state in self._saved_page_states:
                self.__dict__.update(state)
                if self._pageNumber > 1:
                    self._draw_header_footer(total)
                canvas_module.Canvas.showPage(self)
            canvas_module.Canvas.save(self)

        def _draw_header_footer(self, total):
            self.saveState()
            self.setFont('Helvetica', 8)
            self.setFillColor(GREY_TEXT)
            self.drawString(MARGIN, PAGE_H - MARGIN + 5, short_title)
            self.drawRightString(PAGE_W - MARGIN, PAGE_H - MARGIN + 5, doc_id)
            self.setStrokeColor(colors.HexColor('#cccccc'))
            self.line(MARGIN, PAGE_H - MARGIN, PAGE_W - MARGIN, PAGE_H - MARGIN)
            self.line(MARGIN, MARGIN, PAGE_W - MARGIN, MARGIN)
            self.drawString(MARGIN, MARGIN - 10, doc_id)
            self.drawRightString(PAGE_W - MARGIN, MARGIN - 10, f'Page {self._pageNumber} of {total}')
            self.restoreState()
    return NumberedCanvas


def build_pdf(title, short_title, doc_id, project, track, status, prep_date, md_files, out_path):
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle(name='TOC1', fontSize=12, leading=16, fontName='Helvetica-Bold', spaceAfter=4, textColor=NAVY),
        ParagraphStyle(name='TOC2', fontSize=12, leading=14, leftIndent=16, fontName='Helvetica'),
        ParagraphStyle(name='TOC3', fontSize=12, leading=13, leftIndent=32, fontName='Helvetica-Oblique'),
    ]

    flow = []
    # Cover page
    flow.append(Spacer(1, 1.6 * inch))
    flow.append(Paragraph(esc(title), TITLE_STYLE))
    flow.append(Spacer(1, 0.35 * inch))
    flow.append(HRFlowable(width='55%', thickness=1.2, color=NAVY, hAlign='CENTER'))
    flow.append(Spacer(1, 0.5 * inch))
    cover_rows = [
        ('Project', project),
        ('Track', track),
        ('Document Identifier', doc_id),
        ('Version', '1.0'),
        ('Status', status),
        ('Preparation Date', prep_date),
        ('Prepared By', 'Architecture & Engineering'),
    ]
    for label, value in cover_rows:
        flow.append(Paragraph(f'<b>{esc(label)}:</b> {esc(value)}', COVER_FIELD))
    flow.append(PageBreak())

    # TOC
    flow.append(Paragraph('Table of Contents', H1))
    flow.append(toc)
    flow.append(PageBreak())

    for idx, path in enumerate(md_files):
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
        flow.extend(parse_md(text))
        if idx < len(md_files) - 1:
            flow.append(PageBreak())

    frame = Frame(MARGIN, MARGIN + 4, CONTENT_W, PAGE_H - 2 * MARGIN - 10, id='normal')
    doc = BaseDocTemplate(out_path, pagesize=A4, title=title,
                           leftMargin=MARGIN, rightMargin=MARGIN, topMargin=MARGIN, bottomMargin=MARGIN)
    template = PageTemplate(id='main', frames=[frame])
    doc.addPageTemplates([template])

    def afterFlowable(flowable):
        if isinstance(flowable, Heading):
            text = re.sub('<[^<]+?>', '', flowable.text)
            doc.notify('TOCEntry', (flowable.level, text, doc.page))

    doc.afterFlowable = afterFlowable
    doc.multiBuild(flow, canvasmaker=make_canvas_class(short_title, doc_id))
    print('Wrote', out_path)
