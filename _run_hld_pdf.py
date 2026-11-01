import os
from _gen_pdf_hld import build_pdf, OUT_DIR, DOCS

HLD_MD = os.path.join(DOCS, '02-solution-design', 'HLD', 'MAL4-HLD.md')

build_pdf(
    title='MAL4 Campaign Review & Approval -- High-Level Design',
    short_title='MAL4 Campaign Review & Approval -- HLD',
    doc_id='MAL4-HLD-v1.0',
    project='Mobile Architecture Lab 4 (MAL4)',
    track='MarTech -- Campaign Review & Approval',
    status='Draft -- Internal Review Pending',
    prep_date='2026-11-01',
    md_files=[HLD_MD],
    out_path=os.path.join(OUT_DIR, 'MAL4-HLD.pdf'),
)
