import os
from _gen_pdf_hld import build_pdf, OUT_DIR, DOCS

LLD_MD = os.path.join(DOCS, '02-solution-design', 'LLD', 'MAL4-LLD.md')

build_pdf(
    title='MAL4 Campaign Review & Approval -- Low-Level Design',
    short_title='MAL4 Campaign Review & Approval -- LLD',
    doc_id='MAL4-LLD-v1.0',
    project='Mobile Architecture Lab 4 (MAL4)',
    track='MarTech -- Campaign Review & Approval',
    status='Draft -- Internal Review Pending',
    prep_date='2026-11-01',
    md_files=[LLD_MD],
    out_path=os.path.join(OUT_DIR, 'MAL4-LLD.pdf'),
)
