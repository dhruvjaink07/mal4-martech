import os
import re
import sys
import subprocess
from pathlib import Path

WORKSPACE = Path("/Users/phodeco/Tech/study/mal4-martech-campaign-arch")
DOCS_DIR = WORKSPACE / "docs"
ADR_DIR = DOCS_DIR / "03-architecture-decisions"
DEFENCE_DIR = DOCS_DIR / "08-architecture-defence"
SOLUTION_DIR = DOCS_DIR / "02-solution-design"
OUT_DIR = DOCS_DIR / "09-architecture-deliverables"
OUT_DIR.mkdir(parents=True, exist_ok=True)

HTML_OUT = ADR_DIR / "MAL4-ADR.html"
PDF_OUT = OUT_DIR / "MAL4-ADR.pdf"
PDF_COPY = ADR_DIR / "MAL4-ADR.pdf"

def inline_format(text):
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'\*([^*]+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'`([^`]+?)`', r'<code>\1</code>', text)
    text = text.replace(r'$\rightarrow$', '&rarr;')
    text = text.replace(r'\rightarrow', '&rarr;')
    text = text.replace(r'$\le$', '&le;')
    text = text.replace(r'$\ge$', '&ge;')
    text = text.replace(r'$\pm$', '&plusmn;')
    text = re.sub(r'\$([^$]+?)\$', r'<span class="math">\1</span>', text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<span class="doc-link">\1</span>', text)
    
    # Highlight selected alternatives in Green
    text = re.sub(r'\(selected\)', r'(<strong class="text-green">selected</strong>)', text, flags=re.IGNORECASE)
    
    # Status badges strictly in GREEN, RED, BLACK
    text = text.replace('Accepted (for the current Solution Design)', '<span class="badge badge-green">Accepted (Solution Design)</span>')
    text = text.replace('Accepted', '<span class="badge badge-green">Accepted</span>')
    text = text.replace('Proposed — Unresolved Conflict, Requires Team Decision Before Final Submission', '<span class="badge badge-red">Proposed &mdash; Unresolved Conflict</span>')
    text = text.replace('Proposed — Unresolved, requires a team decision', '<span class="badge badge-red">Proposed &mdash; Unresolved</span>')
    text = text.replace('Proposed', '<span class="badge badge-red">Proposed</span>')
    text = text.replace('Resolved', '<span class="badge badge-green">Resolved</span>')
    text = text.replace('Adopted', '<span class="badge badge-green">Adopted</span>')
    text = text.replace('Critical', '<span class="badge badge-red">Critical</span>')
    text = text.replace('High', '<span class="badge badge-black">High</span>')
    text = text.replace('Must', '<span class="badge badge-black">Must</span>')
    return text

def parse_markdown_to_html(md_content):
    lines = md_content.split('\n')
    html_lines = []
    in_code_block = False
    code_lang = ''
    code_lines = []
    in_table = False
    table_lines = []
    in_list = False
    list_type = None

    def flush_table():
        nonlocal in_table, table_lines
        if not table_lines:
            in_table = False
            return
        
        headers = []
        rows = []
        is_header = True
        
        for tline in table_lines:
            tline = tline.strip()
            if not tline.startswith('|'):
                continue
            cols = [c.strip() for c in tline.split('|')[1:-1]]
            if all(re.match(r'^:?-+:?$', c) for c in cols if c):
                is_header = False
                continue
            if is_header:
                headers.append(cols)
            else:
                rows.append(cols)
        
        table_html = ['<div class="table-container"><table>']
        if headers:
            table_html.append('<thead>')
            for hrow in headers:
                table_html.append('<tr>' + ''.join(f'<th>{inline_format(c)}</th>' for c in hrow) + '</tr>')
            table_html.append('</thead>')
        if rows:
            table_html.append('<tbody>')
            for rrow in rows:
                row_cells = []
                for c in rrow:
                    formatted_c = inline_format(c)
                    row_cells.append(f'<td>{formatted_c}</td>')
                table_html.append('<tr>' + ''.join(row_cells) + '</tr>')
            table_html.append('</tbody>')
        table_html.append('</table></div>')
        html_lines.extend(table_html)
        table_lines = []
        in_table = False

    def flush_list():
        nonlocal in_list, list_type
        if in_list:
            html_lines.append(f'</{list_type}>')
            in_list = False
            list_type = None

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Code block
        if stripped.startswith('```'):
            if in_table:
                flush_table()
            if in_list:
                flush_list()
            if not in_code_block:
                in_code_block = True
                code_lang = stripped[3:].strip()
                code_lines = []
            else:
                in_code_block = False
                code_text = '\n'.join(code_lines)
                html_lines.append(f'<pre class="code-block language-{code_lang}"><code>{code_text}</code></pre>')
                code_lines = []
            i += 1
            continue

        if in_code_block:
            code_lines.append(line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))
            i += 1
            continue

        # Tables
        if stripped.startswith('|') and '|' in stripped[1:]:
            if in_list:
                flush_list()
            in_table = True
            table_lines.append(stripped)
            i += 1
            continue
        elif in_table:
            flush_table()

        # Blank line
        if not stripped:
            if in_list:
                flush_list()
            i += 1
            continue

        # Horizontal Rule
        if re.match(r'^(---|___|\*\*\*)$', stripped):
            if in_list:
                flush_list()
            html_lines.append('<hr class="divider" />')
            i += 1
            continue

        # Blockquote / Callouts
        if stripped.startswith('>'):
            if in_list:
                flush_list()
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith('>'):
                qline = lines[i].strip()[1:].strip()
                quote_lines.append(qline)
                i += 1
            qtext = ' '.join(quote_lines)
            
            # Strict Color Classification: RED, GREEN, or BLACK
            box_class = "callout-black"
            if "Warning" in qtext or "Unresolved" in qtext or "Conflict" in qtext or "Risk" in qtext or "divergence" in qtext:
                box_class = "callout-red"
            elif "Accepted" in qtext or "Adopted" in qtext or "Approved" in qtext or "Decision" in qtext:
                box_class = "callout-green"
            elif "**Status:**" in qtext or "**Owner:**" in qtext or "**Traces to:**" in qtext:
                box_class = "callout-black"
            
            html_lines.append(f'<div class="{box_class}">{inline_format(qtext)}</div>')
            continue

        # Headings
        h_match = re.match(r'^(#{1,6})\s+(.*)$', stripped)
        if h_match:
            if in_list:
                flush_list()
            level = len(h_match.group(1))
            htext = h_match.group(2).strip()
            html_lines.append(f'<h{level}>{inline_format(htext)}</h{level}>')
            i += 1
            continue

        # Lists
        ul_match = re.match(r'^[-*]\s+(.*)$', stripped)
        ol_match = re.match(r'^\d+\.\s+(.*)$', stripped)
        if ul_match or ol_match:
            current_type = 'ol' if ol_match else 'ul'
            item_text = (ol_match or ul_match).group(1).strip()
            if not in_list:
                in_list = True
                list_type = current_type
                html_lines.append(f'<{list_type}>')
            elif list_type != current_type:
                flush_list()
                in_list = True
                list_type = current_type
                html_lines.append(f'<{list_type}>')
            html_lines.append(f'<li>{inline_format(item_text)}</li>')
            i += 1
            continue
        elif in_list:
            flush_list()

        # Regular Paragraph
        html_lines.append(f'<p>{inline_format(stripped)}</p>')
        i += 1

    if in_table:
        flush_table()
    if in_list:
        flush_list()

    return '\n'.join(html_lines)

def build_adr_html():
    print("Reading ADR files...")
    readme_text = (ADR_DIR / "README.md").read_text(encoding="utf-8")
    adr1_text = (ADR_DIR / "ADR-001-architecture-style.md").read_text(encoding="utf-8")
    adr2_text = (ADR_DIR / "ADR-002-data-consistency.md").read_text(encoding="utf-8")
    adr3_text = (ADR_DIR / "ADR-003-event-processing.md").read_text(encoding="utf-8")
    adr4_text = (ADR_DIR / "ADR-004-authorization-and-deployment-boundary.md").read_text(encoding="utf-8")
    adr5_text = (ADR_DIR / "ADR-005-persistence-strategy.md").read_text(encoding="utf-8")
    adr6_text = (ADR_DIR / "ADR-006-multistage-approval-backend-reconciliation.md").read_text(encoding="utf-8")
    
    defence_text = (DEFENCE_DIR / "adr-defence.md").read_text(encoding="utf-8")
    traceability_text = (DOCS_DIR / "07-quality-attributes" / "traceability.md").read_text(encoding="utf-8")

    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>MAL4 MarTech — Architecture Decision Records (ADRs)</title>
<style>
/* ==========================================================================
   STRICT PALETTE: RED, GREEN, BLACK (+ white/gray backgrounds)
   HIGH READABILITY, PUBLICATION-GRADE TYPOGRAPHY
   ========================================================================== */

@page {{
  size: A4 portrait;
  margin: 12mm 14mm 12mm 14mm;
  @top-left {{
    content: "MAL4 MarTech • Architecture Decision Records (ADRs)";
    font-size: 7.5pt;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #000000;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }}
  @top-right {{
    content: "Document ID: MAL4-ADR-v1.0";
    font-size: 7.5pt;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #000000;
    font-weight: 700;
  }}
  @bottom-left {{
    content: "Mobile Architecture Lab 4 (MAL4) • Dimension: Architecture Decisions & Governance";
    font-size: 7.5pt;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #333333;
  }}
  @bottom-right {{
    content: "Page " counter(page);
    font-size: 7.5pt;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #000000;
    font-weight: 800;
  }}
}}

*, *::before, *::after {{
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}}

body {{
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  color: #000000;
  background-color: #ffffff;
  line-height: 1.42;
  font-size: 9pt;
  -webkit-font-smoothing: antialiased;
}}

/* Typography */
h1 {{
  font-size: 15pt;
  font-weight: 900;
  color: #000000;
  line-height: 1.2;
  margin-top: 13pt;
  margin-bottom: 6pt;
  border-bottom: 2.5px solid #000000;
  padding-bottom: 3pt;
  page-break-after: avoid;
  letter-spacing: -0.01em;
}}

h2 {{
  font-size: 11.5pt;
  font-weight: 800;
  color: #000000;
  line-height: 1.25;
  margin-top: 10pt;
  margin-bottom: 4.5pt;
  border-bottom: 1.2px solid #000000;
  padding-bottom: 2.5pt;
  page-break-after: avoid;
}}

h3 {{
  font-size: 9.5pt;
  font-weight: 700;
  color: #000000;
  line-height: 1.3;
  margin-top: 8pt;
  margin-bottom: 3.5pt;
  page-break-after: avoid;
}}

p {{
  margin-bottom: 5.5pt;
  color: #111111;
}}

strong {{
  font-weight: 700;
  color: #000000;
}}

em {{
  font-style: italic;
}}

.text-green {{
  color: #166534;
  font-weight: 800;
}}

.text-red {{
  color: #991b1b;
  font-weight: 800;
}}

code {{
  font-family: "SF Mono", Menlo, Consolas, Monaco, monospace;
  font-size: 8pt;
  background-color: #f5f5f5;
  color: #000000;
  padding: 1px 3.5px;
  border-radius: 3px;
  border: 1px solid #d4d4d4;
  font-weight: 500;
}}

.math {{
  font-family: "SF Mono", Menlo, Consolas, monospace;
  font-style: italic;
  color: #000000;
  font-weight: 600;
}}

.doc-link {{
  color: #000000;
  font-weight: 700;
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 2px;
}}

/* Lists */
ul, ol {{
  margin-left: 16pt;
  margin-bottom: 7pt;
}}

li {{
  margin-bottom: 2.5pt;
  color: #111111;
}}

/* Tables */
.table-container {{
  margin-top: 6pt;
  margin-bottom: 8pt;
  page-break-inside: avoid;
}}

table {{
  width: 100%;
  border-collapse: collapse;
  font-size: 8pt;
  line-height: 1.28;
  border: 1.5px solid #000000;
}}

th, td {{
  padding: 4.5pt 6.5pt;
  border: 1px solid #000000;
  text-align: left;
  vertical-align: top;
}}

th {{
  background-color: #000000;
  color: #ffffff;
  font-weight: 800;
  font-size: 7.5pt;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border: 1px solid #000000;
}}

tr:nth-child(even) td {{
  background-color: #fafafa;
}}

/* Strict Red / Green / Black Callouts */
.callout-black {{
  background-color: #f9f9f9;
  border: 1px solid #000000;
  border-left: 5px solid #000000;
  padding: 6pt 10pt;
  margin-top: 6pt;
  margin-bottom: 8pt;
  font-size: 8.5pt;
  color: #000000;
  border-radius: 0 4pt 4pt 0;
}}

.callout-green {{
  background-color: #f0fdf4;
  border: 1px solid #16a34a;
  border-left: 5px solid #16a34a;
  padding: 6pt 10pt;
  margin-top: 6pt;
  margin-bottom: 8pt;
  font-size: 8.5pt;
  color: #166534;
  border-radius: 0 4pt 4pt 0;
}}

.callout-red {{
  background-color: #fef2f2;
  border: 1px solid #dc2626;
  border-left: 5px solid #dc2626;
  padding: 6pt 10pt;
  margin-top: 6pt;
  margin-bottom: 8pt;
  font-size: 8.5pt;
  color: #991b1b;
  border-radius: 0 4pt 4pt 0;
}}

/* Code Blocks */
pre.code-block {{
  background-color: #fafafa;
  color: #000000;
  padding: 7pt 9pt;
  border-radius: 4pt;
  font-family: "SF Mono", Menlo, Consolas, Monaco, monospace;
  font-size: 7.5pt;
  line-height: 1.35;
  overflow-x: auto;
  margin-top: 6pt;
  margin-bottom: 8pt;
  page-break-inside: avoid;
  border: 1.5px solid #000000;
}}

pre.code-block code {{
  background-color: transparent;
  color: inherit;
  padding: 0;
  border: none;
  font-size: inherit;
}}

/* Strict Badges */
.badge {{
  display: inline-block;
  padding: 1.5pt 5pt;
  font-size: 7pt;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-radius: 3pt;
  vertical-align: middle;
}}

.badge-green {{
  background-color: #f0fdf4;
  color: #166534;
  border: 1.5px solid #16a34a;
}}

.badge-red {{
  background-color: #fef2f2;
  color: #991b1b;
  border: 1.5px solid #dc2626;
}}

.badge-black {{
  background-color: #000000;
  color: #ffffff;
  border: 1.5px solid #000000;
}}

/* Layout & Page Breaks */
.page-break {{
  page-break-before: always;
  break-before: page;
}}

.cover-page {{
  padding-top: 8pt;
  padding-bottom: 8pt;
}}

.cover-header {{
  border-bottom: 3.5px solid #000000;
  padding-bottom: 8pt;
  margin-bottom: 12pt;
}}

.cover-eyebrow {{
  font-size: 8pt;
  font-weight: 900;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #000000;
  margin-bottom: 3pt;
  display: flex;
  align-items: center;
  gap: 5pt;
}}

.cover-eyebrow .dot-green {{
  width: 7px;
  height: 7px;
  background-color: #16a34a;
  border-radius: 50%;
  display: inline-block;
}}

.cover-title {{
  font-size: 21pt;
  font-weight: 900;
  color: #000000;
  line-height: 1.15;
  margin-bottom: 4pt;
  letter-spacing: -0.02em;
}}

.cover-subtitle {{
  font-size: 9.5pt;
  color: #222222;
  font-weight: 600;
  line-height: 1.35;
}}

.cover-grid {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8pt;
  margin-top: 9pt;
  margin-bottom: 10pt;
}}

.cover-meta-card {{
  background-color: #ffffff;
  border: 1.5px solid #000000;
  border-radius: 4pt;
  padding: 6pt 8pt;
}}

.cover-meta-row {{
  font-size: 8pt;
  display: flex;
  justify-content: space-between;
  margin-bottom: 2.5pt;
}}

.cover-meta-label {{
  color: #444444;
  font-weight: 700;
}}

.cover-meta-value {{
  color: #000000;
  font-weight: 800;
}}

.executive-brief-green {{
  background-color: #f0fdf4;
  border: 2px solid #16a34a;
  border-radius: 4pt;
  padding: 8pt 10pt;
  margin-top: 7pt;
  margin-bottom: 8pt;
}}

.executive-brief-green h3 {{
  color: #166534;
  margin-top: 0;
  margin-bottom: 3.5pt;
  font-size: 9.5pt;
  font-weight: 800;
}}

.executive-brief-green p {{
  font-size: 8pt;
  color: #14532d;
  line-height: 1.38;
  margin-bottom: 3pt;
}}

.executive-brief-red {{
  background-color: #fef2f2;
  border: 2px solid #dc2626;
  border-radius: 4pt;
  padding: 7pt 10pt;
  margin-top: 6pt;
  margin-bottom: 8pt;
}}

.executive-brief-red h3 {{
  color: #991b1b;
  margin-top: 0;
  margin-bottom: 3.5pt;
  font-size: 9.5pt;
  font-weight: 800;
}}

.executive-brief-red p {{
  font-size: 8pt;
  color: #7f1d1d;
  line-height: 1.38;
  margin-bottom: 3pt;
}}

hr.divider {{
  border: none;
  border-top: 1.5px solid #000000;
  margin: 10pt 0;
}}
</style>
</head>
<body>

<!-- COVER / INTRO PAGE -->
<div class="cover-page">
  <div class="cover-header">
    <div class="cover-eyebrow"><span class="dot-green"></span> Mobile Architecture Lab 4 (MAL4) &bull; MarTech Campaign Review &amp; Approval</div>
    <div class="cover-title">Architecture Decision Records</div>
    <div class="cover-subtitle">Formal Architectural Decisions, Decision Drivers, Alternatives Evaluation, Trade-Off Analyses, and Requirements Reconciliation (ADR-001 through ADR-006)</div>
  </div>

  <div class="cover-grid">
    <div class="cover-meta-card">
      <div class="cover-meta-row"><span class="cover-meta-label">Document ID:</span><span class="cover-meta-value">MAL4-ADR-v1.0</span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Track:</span><span class="cover-meta-value">MarTech &mdash; Campaign Review &amp; Approval</span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Author / Role:</span><span class="cover-meta-value">Architecture &amp; Engineering Lead</span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Last Updated:</span><span class="cover-meta-value">2026-11-01</span></div>
    </div>
    <div class="cover-meta-card">
      <div class="cover-meta-row"><span class="cover-meta-label">Document Status:</span><span class="cover-meta-value"><span class="badge badge-green">Accepted / Reviewed</span></span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Primary Style:</span><span class="cover-meta-value">Modular Monolith / Clean-Lite</span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Solution Design:</span><span class="cover-meta-value">MAL4-HLD.md / MAL4-LLD.md</span></div>
      <div class="cover-meta-row"><span class="cover-meta-label">Reconciliation:</span><span class="cover-meta-value"><span class="badge badge-red">ADR-006 Tracked</span></span></div>
    </div>
  </div>

  <div class="executive-brief-green">
    <h3>Executive Architecture Brief &amp; Core Decision Governance</h3>
    <p>This document formalizes the complete Architecture Decision Records (ADRs) for the MAL4 Campaign Review &amp; Approval platform. ADRs 001 through 005 establish the foundation of the current Solution Design (HLD/LLD): a Modular Monolith with Feature-First Clean-Architecture-lite layering, immutable full-snapshot campaign versioning, dual-check optimistic concurrency control, in-process domain events, and on-device role-based access control sized for a two-person team and hackathon timeline.</p>
    <p>Every decision reflects explicit trade-offs: full Clean Architecture ceremony is pruned to preserve velocity while retaining domain isolation; distributed transaction machinery is rejected to fit a single-deployable mobile footprint; and persistence is isolated behind repository interfaces to maintain future evolution seams.</p>
  </div>

  <div class="executive-brief-red">
    <h3>Architectural Divergence &amp; Reconciliation Governance (ADR-006)</h3>
    <p><strong>Explicit Conflict Disclosure:</strong> Inspection of the requirements baseline (01-problem-understanding, 04-workflows, 06-data-design) identified that it now specifies a 3-stage sequential approval pipeline (Creative &rarr; Compliance &rarr; Finance) with SHA-256 snapshot hashing, server-side relational enforcement, and a transactional outbox table. ADR-006 formally tracks this discrepancy rather than papering over it, outlining three defensible resolution options for team adoption.</p>
  </div>

  <h2>ADR Status Summary Matrix</h2>
  <div class="table-container">
    <table>
      <thead>
        <tr>
          <th>ADR ID</th>
          <th>Decision Title</th>
          <th>Status</th>
          <th>Architectural Scope &amp; Role</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>ADR-001</strong></td>
          <td>Overall Architecture Style</td>
          <td><span class="badge badge-green">Accepted</span></td>
          <td>Modular Monolith, Feature-First organization, Clean-lite layering, MVVM, Repository pattern</td>
        </tr>
        <tr>
          <td><strong>ADR-002</strong></td>
          <td>Campaign Versioning, Approval-Version Binding &amp; OCC</td>
          <td><span class="badge badge-green">Accepted</span></td>
          <td>Immutable snapshots, optimistic concurrency control, dual domain/repository conflict checks</td>
        </tr>
        <tr>
          <td><strong>ADR-003</strong></td>
          <td>In-Process Domain Events for Decoupling</td>
          <td><span class="badge badge-green">Accepted</span></td>
          <td>Post-commit domain events, non-blocking asynchronous notification dispatch</td>
        </tr>
        <tr>
          <td><strong>ADR-004</strong></td>
          <td>Authorization Boundary &amp; No-Backend Model</td>
          <td><span class="badge badge-green">Accepted (Solution Design)</span></td>
          <td>On-device RBAC &amp; Anti-Self-Approval; explicit disclosure of no-server boundary</td>
        </tr>
        <tr>
          <td><strong>ADR-005</strong></td>
          <td>Local-First Persistence Strategy</td>
          <td><span class="badge badge-green">Accepted (Solution Design)</span></td>
          <td>Drift over SQLite; atomic transaction across campaign state and audit log</td>
        </tr>
        <tr>
          <td><strong>ADR-006</strong></td>
          <td>Multi-Stage Approval &amp; Backend Reconciliation</td>
          <td><span class="badge badge-red">Proposed &mdash; Unresolved</span></td>
          <td>Reconciliation between 6-state Solution Design and 3-stage server-backed requirements</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

<div class="page-break"></div>

<!-- SECTION 1: README & RELATIONSHIPS -->
<h1>Section 1: Architecture Decision Records &mdash; Index &amp; Relationships</h1>
{parse_markdown_to_html(readme_text)}

<div class="page-break"></div>

<!-- SECTION 2: ADR-001 -->
<h1>Section 2: ADR-001 &mdash; Overall Architecture Style</h1>
{parse_markdown_to_html(adr1_text)}

<div class="page-break"></div>

<!-- SECTION 3: ADR-002 -->
<h1>Section 3: ADR-002 &mdash; Data Consistency, Versioning &amp; Concurrency</h1>
{parse_markdown_to_html(adr2_text)}

<div class="page-break"></div>

<!-- SECTION 4: ADR-003 -->
<h1>Section 4: ADR-003 &mdash; In-Process Domain Events</h1>
{parse_markdown_to_html(adr3_text)}

<div class="page-break"></div>

<!-- SECTION 5: ADR-004 -->
<h1>Section 5: ADR-004 &mdash; Authorization Boundary &amp; Deployment Model</h1>
{parse_markdown_to_html(adr4_text)}

<div class="page-break"></div>

<!-- SECTION 6: ADR-005 -->
<h1>Section 6: ADR-005 &mdash; Persistence Strategy</h1>
{parse_markdown_to_html(adr5_text)}

<div class="page-break"></div>

<!-- SECTION 7: ADR-006 -->
<h1>Section 7: ADR-006 &mdash; Multi-Stage &amp; Backend Reconciliation</h1>
{parse_markdown_to_html(adr6_text)}

<div class="page-break"></div>

<!-- SECTION 8: ARCHITECTURE DEFENCE (ADR DEFENCE) -->
<h1>Section 8: Architecture Decision Defence &mdash; Spoken-Ready Notes</h1>
<div class="callout-black">
  <strong>Source:</strong> <code>docs/08-architecture-defence/adr-defence.md</code> &bull; Rehearsed, cross-examination-ready talking points covering core decisions, alternatives rejected, technical trade-offs, limitations, and revisit criteria.
</div>
{parse_markdown_to_html(defence_text)}

<div class="page-break"></div>

<!-- SECTION 9: TRACEABILITY MATRIX -->
<h1>Section 9: Requirements &amp; Architecture Traceability Matrix</h1>
<div class="callout-black">
  <strong>Source:</strong> <code>docs/07-quality-attributes/traceability.md</code> &bull; Comprehensive end-to-end forward and backward traceability mapping requirements to ADRs, domain entities, and quality attributes.
</div>
{parse_markdown_to_html(traceability_text)}

</body>
</html>
"""
    HTML_OUT.write_text(html_content, encoding="utf-8")
    print(f"Generated HTML deliverable at: {HTML_OUT}")

    print("Compiling PDF via Headless Chrome (Strict Red, Green, Black palette)...")
    chrome_cmd = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "--headless",
        "--disable-gpu",
        f"--print-to-pdf={PDF_OUT}",
        "--no-pdf-header-footer",
        str(HTML_OUT)
    ]
    res = subprocess.run(chrome_cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Chrome error: {res.stderr}")
        sys.exit(1)
    
    # Copy to ADR directory as well
    if PDF_OUT.exists():
        import shutil
        shutil.copy2(PDF_OUT, PDF_COPY)
        print(f"Successfully generated PDF at: {PDF_OUT}")
        print(f"Copied PDF deliverable to: {PDF_COPY}")
        
        # Check page count
        try:
            import pypdf
            reader = pypdf.PdfReader(str(PDF_OUT))
            print(f"Total Page Count: {len(reader.pages)} pages")
        except Exception as e:
            print(f"Could not read PDF metadata: {e}")

if __name__ == "__main__":
    build_adr_html()
