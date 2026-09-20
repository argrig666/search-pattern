#!/usr/bin/env python3
import subprocess
import re
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PDF_PATH = os.path.join(BASE_DIR, "search pattern.pdf")
PILOT_CXR_PATH = os.path.join(BASE_DIR, "chest_radiograph.txt")
OUTPUT_TXT_PATH = os.path.join(BASE_DIR, "search_patterns.txt")

# Studies requiring manual page offset correction due to layout differences in PDF
MANUAL_MAP = {
    'cta iliofemoral runoff and lower extremities': 225,
    'i-123 iodine uptake test': 293,
    'fluciclovine f18 (axumin) pet/ct': 303,
    'fluciclovine fl 8 (axumin) pet/ ct': 303,
    'us abdomen for complications of malrotation': 321,
    'us for intussusception': 323,
    'some rules of thumb on when to provide preliminary reports': 360,
    'cta pe (ct angiogram for pulmonary embolus)': 36,
    'us breast': 347,
    'us transcranial doppler (tcd)': 265,
    'us transcranial doppler (fcd)': 265,
    'f18 fdg pet/ct whole body': 297,
    'gallium-68 dotatate pet/ct': 300
}

SEC_MAP = {
    'CHEST IMAGING': 'CHEST',
    'BODY IMAGING': 'BODY',
    'NEUROIMAGING': 'NEURO',
    'MUSCULOSKELETAL (MSK) IMAGING': 'MSK',
    'CARDIAC IMAGING': 'CARDIAC',
    'PERIPHERAL VASCULAR IMAGING': 'PERIPHERAL VASCULAR',
    'ULTRASOUND IMAGING': 'ULTRASOUND',
    'NUCLEAR MEDICINE': 'NUCLEAR MEDICINE',
    'PEDIATRIC IMAGING': 'PEDIATRIC',
    'BREAST IMAGING': 'BREAST',
}

def clean_modality(mod_raw):
    mod_raw = re.sub(r'^\d+\.\s*', '', mod_raw).strip()
    mod_upper = mod_raw.upper()
    if 'RADIOGRAPHIC' in mod_upper: return 'RADIOGRAPH'
    if 'FLUOROSCOPIC' in mod_upper: return 'FLUOROSCOPY'
    if 'MAMMOGRAPHY' in mod_upper: return 'MAMMOGRAPHY & US'
    if 'CT' in mod_upper and 'PET' not in mod_upper: return 'CT'
    if 'MRI' in mod_upper: return 'MRI'
    if 'ULTRASOUND' in mod_upper:
        if 'BODY' in mod_upper: return 'BODY & GENERAL US'
        if 'VASCULAR' in mod_upper: return 'VASCULAR US'
        if 'TRANSPLANT' in mod_upper: return 'TRANSPLANT US'
        return 'ULTRASOUND'
    if 'COMMON' in mod_upper or 'EMERGENT' in mod_upper: return 'COMMON & EMERGENT'
    if 'GENERAL NUCLEAR' in mod_upper: return 'GENERAL NM'
    if 'PET' in mod_upper: return 'PET/CT'
    return mod_upper

def clean_title(title):
    t = title.strip()
    t = re.sub(r'\(fCD\)', '(TCD)', t, flags=re.IGNORECASE)
    t = re.sub(r'Fl\s*8', 'F18', t, flags=re.IGNORECASE)
    t = re.sub(r'PET\s*/\s*CT', 'PET/CT', t, flags=re.IGNORECASE)
    t = re.sub(r'N\s*eek\b', 'Neck', t, flags=re.IGNORECASE)
    t = re.sub(r'\blntussusception\b', 'Intussusception', t, flags=re.IGNORECASE)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

# Patterns for meta-sections to drop completely
META_PATTERNS = [
    r'\b(?:indications?|history|priors?|clinical\s+context|patient\s+factors)\b',
    r'\b(?:technique|adequacy|limitations?|positioning|troubleshooting|technical\s+considerations)\b',
    r'\b(?:scouts?|localizers?|scanograms?|topograms?)\b',
    r'scout\s*/\s*localizer',
    r'\b(?:quality\s+assessment|qa\s+assessment|prepare\s+the\s+patient|perform\s+the\s+study)\b',
    r'\b(?:gestalt|triage|first\s+impression|first\s+pass)\b',
    r'\b(?:proofread|preliminary\s+reports?|consultation|workflow|structured\s+reporting|last\s+checks?)\b',
    r'\b(?:study\s+adequacy|study\s+technique|pre-assessment\s+checks?)\b',
    r'\b(?:patient\s+demographics|cancer/\s*surgical\s+history|syndromic/\s*association\s+patterns)\b',
    r'\b(?:double\s+check(?:ing)?\s+for\s+serious\s+pathology)\b',
]

SUBITEM_META_PATTERNS = [
    r'^\s*(?:check\s+(?:the\s+)?)?(?:indication|indications|history|priors?)\b',
    r'^\s*(?:history,\s*indication,\s*priors?|indication,\s*history)\b',
    r'^\s*(?:assess\s+(?:the\s+)?)?(?:adequacy|technique|limitations?|positioning)\b',
    r'^\s*(?:study\s+adequacy|study\s+technique|pre-assessment\s+checks?)\b',
    r'^\s*(?:adequacy,\s*technique,\s*limitations?)\b',
    r'^\s*(?:suboptimal\s+quality\s+or\s+adequacy|study\s+limitations)\b',
    r'^\s*(?:look\s+at\s+(?:the\s+)?)?(?:scouts?|localizers?|scanograms?|topograms?)\b',
    r'scout\s*/\s*localizer',
    r'\b(?:on|from)\s+the\s+localizers?\b',
    r'localizers?\s+(?:for\s+incidentals?|\(t2\s+haste\))',
    r'^\s*(?:localizers?|scouts?)\b',
    r'^\s*(?:gestalt|triage|start\s+with\s+the\s+axials|first\s+impression|first\s+pass)\b',
    r'^\s*(?:proofread|preliminary\s+reports?|consultation|workflow)\b',
    r'^\s*(?:patient\s+demographics|cancer/\s*surgical\s+history|syndromic/\s*association\s+patterns)\b',
    r'^\s*(?:compare\s+(?:as\s+needed\s+|with\s+|to\s+)?priors?|comparison\s+to\s+priors?)\b',
    r'^\s*(?:correlat(?:e|ing)\s+.*with\s+priors?)\b',
    r'^\s*remember\s+to\s+compare\s+to\s+prior',
    r'^\s*(?:overall\s+)?does\s+the\s+patient\s+look\s+better,\s*worse,\s*or\s+similar.*priors?',
    r'^\s*assess\s+across\s+multiple\s+priors',
    r'^\s*priors?\s*$',
    r'^\s*indication,\s*history\s*$',
    r'^\s*what\s+is\s+the\s+birth\s+history',
    r'^\s*what\s+was\s+the\s+indication\s+for',
    r'^\s*(?:perform\s+(?:any\s+|a\s+few\s+)?last\s+checks|last\s+checks?\s*(?:and\s+proofread)?)\b',
    r'^\s*proofread(?:\s+and\s+sign)?\b',
    r'^\s*always\s+remember\s+to\s+proofread\b',
    r'^\s*are\s+there\s+limitations\s+in\s+acoustic\s+windows\b',
    r'^\s*consider\s+the\s+need\s+for\s+physiologic\s+maneuvers\s+or\s+patient\s+positioning\b',
    r'^\s*remember\s+(?:the\s+)?images?\s+anatomy\s+and\s+technique\s+affects\s+billing\b',
    r'^\s*every\s+administration\s+of\s+contrast\s+is\s+an\s+opportunity\b',
    r'^\s*be\s+careful\s+to\s+check\s+any\s+areas\s+of\s+the\s+body\s+that\s+are\s+incidentally\s+imaged\s+on\s+the\s+localizers?\b',
    r'^\s*pay\s+special\s+attention\s+to\s+.*(?:imaged\s+on\s+the\s+localizer)\b',
]

# Patterns for rhetorical / non-anatomical items to drop
RHETORICAL_PATTERNS = [
    r'\b(?:major\s+blind\s+spots?|common\s+blind\s+spots?|blind\s+spots?\s+are\s+central)\b',
    r'\b(?:easily\s+missed|often\s+missed|common\s+source\s+of)\b',
    r'\b(?:useful\s+to\s+know|it\s+can\s+be\s+useful\s+to\s+know)\b',
    r'\b(?:scroll\s+through\s+the\s+thicker|use\s+3d-recons\s+if)\b',
    r'\b(?:if\s+available\s+or\s+producible,\s*use\s+mips)\b',
    r'\b(?:keep\s+in\s+mind\s+that|remember\s+that\s+the\s+baseline)\b',
    r'\b(?:as\s+i\s+close\s+the\s+study|take\s+one\s+last\s+overall)\b',
    r'\b(?:scroll\s+slowly|insist\s+on|use\s+thin\s+slices|use\s+mprs?)\b',
    r'\b(?:use\s+(?:lung|bone|soft\s+tissue|brain|subdural)\s+windows?)\b',
    r'\b(?:switch\s+to\s+(?:lung|bone|soft\s+tissue|brain)\s+windows?)\b',
    r'\b(?:you\'re\s+mostly\s+looking\s+for|the\s+major\s+things\s+you\s+are\s+looking\s+for)\b',
    r'\b(?:for\s+help\s+in\s+seeing|to\s+help\s+in\s+seeing)\b',
    r'\b(?:it\s+may\s+be\s+helpful\s+to\s+split\s+them)\b',
    r'\b(?:starting\s+superiorly|starting\s+inferiorly)\b',
    r'\b(?:double\s+check\s+to\s+make\s+sure\s+that\s+you\s+saw)\b',
    r'\b(?:are\s+there\s+any\s+of\s+the\s+above|did\s+you\s+miss\s+any\s+potentially)\b',
    r'\b(?:as\s+described|as\s+above|repeat\s+the\s+search\s+pattern|repeat\s+the\s+above)\b',
    r'\b(?:decide\s+whether\s+you\s+will\s+do)\b',
    r'\b(?:you\s+may\s+be\s+the\s+only\s+person\s+to\s+notice)\b',
    r'\b(?:you\s+(?:could|can|may)\s+also\s+repeat)\b',
    r'\b(?:it\s+is\s+important\s+to\s+be\s+very\s+specific\s+about\s+numbering)\b',
    r'\b(?:use\s+a\s+similar\s+(?:process|search\s+pattern|anatomic\s+search\s+pattern)\s+as)\b',
    r'\b(?:perform\s+a\s+quick\s+search\s+pattern\s+through\s+the\s+anatomy)\b',
    r'\b(?:(?:always\s+)?keep\s+in\s+mind)\b',
]

BANNER_PATTERNS = [
    r'[A-Z\s\(\)]+IMAGING:.*',
    r'[A-Z\s]+MEDICINE:.*',
    r'[A-Z\s]+OPTIMIZATION:.*',
    r'MUSCULOSKELETAL.*',
    r'NEUROIMAGING.*',
    r'Radiographic Studies.*',
    r'CT Studies.*',
    r'MRI Studies.*',
    r'Fluoroscopic Studies.*',
    r'Ultrasound Studies.*',
    r'LONG\s+H\.?\s+TU.*',
    r'AMI\s+N?\.?\s+RUBINOWITZ.*',
    r'ISABEL\s+CORTOPASSI.*',
    r'S\.\s*A\.\s*JAMAL\s+BOKHARI.*',
    r'MAHAN\s+MATHUR.*',
    r'RAJ\s+R\.\s+AYYAGARI.*',
    r'ANNE\s+MARIE\s+BOUSTANI.*',
    r'JACK\s+PORRINO.*',
    r'LESLIE\s+SCOUTT.*',
    r'CICERO\s+T\.\s+SILVA.*',
    r'&\s*ANNIE\s+WANG.*',
    r'^\s*SEARCH\s+PATTERN\s*$',
    r'^\s*\d+\s*$'
]

def strip_banner_text(text):
    for pat in BANNER_PATTERNS:
        text = re.sub(pat, '', text, flags=re.IGNORECASE)
    return text.strip()

def is_meta(text):
    for pat in META_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False

def is_subitem_meta(text):
    for pat in SUBITEM_META_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False

def is_rhetorical(text):
    for pat in RHETORICAL_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False

def clean_telegraphic(text):
    text = text.strip()
    prefixes = [
        (r'^in\s+the\s+setting\s+of\s+[^,]+,\s*(?:it\s+is\s+important\s+to\s+check\s+)?(?:posterior\s+to\s+the\s+orbits,?\s*for\s+)?(?:preservation\s+of\s+(?:the\s+)?)?', ''),
        (r'^if\s+you\s+see\s+([^,]+),\s*check\s+there\s+as\s+well', r'\1'),
        (r'^when\s+(?:looking\s+at|evaluating|checking)\s+[^,]+,\s*', ''),
        (r'^it\s+(?:can\s+be|is)\s+(?:very\s+)?helpful\s+to\s+(?:try\s+to\s+)?(?:look\s+at|find|check)\s+', ''),
        (r'^be\s+especially\s+(?:careful|vigilant)\s+(?:to\s+look\s+for|for)\s+', ''),
        (r'^(?:make\s+sure\s+to|be\s+sure\s+to|be\s+particularly\s+sure\s+to)\s+(?:look\s+at|check|assess|review)\s+(?:the\s+)?', ''),
        (r'^make\s+sure\s+(?:to\s+|that\s+(?:you\s+|there\s+are\s+|there\s+is\s+)?)', ''),
        (r'^(?:remember\s+to\s+)?pay\s+special\s+attention\s+to\s+(?:the\s+)?', ''),
        (r'^(?:remember\s+to\s+)(?:look\s+at|check|assess|examine)\s+(?:the\s+)?', ''),
        (r'^look\s+to\s+see\s+(?:if\s+there\s+is|if\s+there\s+are|if|that)\s+(?:any\s+)?', ''),
        (r'^look\s+(?:specifically\s+|closely\s+)?(?:for\s+signs\s+of|for\s+evidence\s+of|for|at|to\s+see\s+if)\s+(?:the\s+|any\s+)?', ''),
        (r'^(?:specifically\s+)?(?:at\s+the\s+|at\s+)', ''),
        (r'^(?:get\s+a\s+look\s+at\s+(?:all\s+the\s+|the\s+)?)', ''),
        (r'^(?:specifically\s+check\s+(?:the\s+)?)', ''),
        (r'^(?:imaged\s+facial\s+bones:\s*(?:the\s+)?)', ''),
        (r'^(?:trace\s+(?:the\s+|each\s+)?)', ''),
        (r'^(?:now,\s*|now\s+)?check\s+(?:specifically\s+)?(?:for|the|any)\s+', ''),
        (r'^(?:now,\s*|now\s+)?assess\s+(?:specifically\s+)?(?:for|the|any)\s+', ''),
        (r'^(?:now,\s*|now\s+)?examine\s+(?:the|any)\s+', ''),
        (r'^(?:now,\s*|now\s+)?evaluate\s+(?:the|any)\s+', ''),
        (r'^take\s+a\s+quick\s+look\s+at\s+(?:the\s+)?', ''),
        (r'^note\s+(?:any|the)\s+', ''),
        (r'^are\s+there\s+(?:any)?\s+', ''),
        (r'^is\s+there\s+(?:any)?\s+', ''),
        (r'^did\s+you\s+(?:miss)?\s+', ''),
        (r'^integrity\s+of\s+(?:the\s+)?', ''),
        (r'^preservation\s+of\s+(?:the\s+)?(?:fat\s+in\s+(?:the\s+)?|fat\s+planes\s+in\s+(?:the\s+)?|fat\s+planes\s+within\s+(?:the\s+)?)?', ''),
        (r'^as\s+i\s+close\s+the\s+study,\s*(?:i\s+double\s+check\s+to\s+make\s+such\s+i\s+did\s+not\s+miss\s+)?(?:a\s+subtle\s+)?', ''),
        (r'^(?:you\s+may\s+(?:often\s+)?see\s+(?:the\s+)?)', ''),
        (r'^(?:usual\s+things\s+you\s+will\s+see\s+are\s+(?:the\s+)?)', ''),
    ]
    for pat, repl in prefixes:
        text = re.sub(pat, repl, text, flags=re.IGNORECASE).strip()
    
    text = re.sub(r'^(?:fat\s+in\s+the\s+)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'^(?:fat\s+planes\s+)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\bhoney\b', 'bony', text, flags=re.IGNORECASE)
    text = re.sub(r'\bTl\b', 'T1', text)
    text = re.sub(r'\bBO\b', 'B0', text)
    text = re.sub(r'([A-Z]{2,})\s+s\b', r'\1s', text)
    
    sentences = re.split(r'(?<=[.!?])\s+', text)
    if sentences and len(sentences[0]) > 5:
        text = sentences[0]
    text = text.strip().rstrip('.;, ')
    if text:
        text = text[0].upper() + text[1:]
    return text

def split_atoms(text):
    parens = []
    def save_paren(m):
        parens.append(m.group(0))
        return f'__PAREN_{len(parens)-1}__'
    
    protected = re.sub(r'\(.*?\)', save_paren, text)
    
    # Check colon-delimited lists: "Facial bones: NOE, ZMC, ..."
    if ':' in protected and not re.search(r'^\d+:\d+', protected):
        parts = re.split(r':\s*', protected, maxsplit=1)
        prefix = parts[0].strip()
        rest = parts[1].strip()
        subparts = re.split(r'(?:,\s*as\s+well\s+as\s+|;\s*|,\s+and\s+|,\s*)', rest, flags=re.IGNORECASE)
        combined = []
        for sp in subparts:
            sp = sp.strip().rstrip('.,;')
            if sp:
                combined.append(f'{prefix} ({sp})' if len(prefix) < 18 else sp)
        restored = []
        for c in combined:
            for idx, orig in enumerate(parens):
                c = c.replace(f'__PAREN_{idx}__', orig)
            if c:
                restored.append(c[0].upper() + c[1:])
        if len(restored) > 1:
            return restored

    # Split on comma, semicolon, or ', as well as' outside parentheses
    split_pattern = r'(?:,\s*as\s+well\s+as\s+|;\s*|,\s+and\s+)'
    parts = re.split(split_pattern, protected, flags=re.IGNORECASE)
    
    results = []
    for p in parts:
        for idx, orig in enumerate(parens):
            p = p.replace(f'__PAREN_{idx}__', orig)
        p = p.strip().rstrip('.,;')
        p = re.sub(r'^(?:the\s+|any\s+|and\s+|as\s+well\s+as\s+)', '', p, flags=re.IGNORECASE).strip()
        if p and len(p) > 2:
            p = p[0].upper() + p[1:]
            results.append(p)
    return results if results else [text]

def get_study_list():
    out = subprocess.run(['pdftotext', PDF_PATH, '-'], capture_output=True, text=True)
    pages = out.stdout.split('\x0c')

    toc_out = subprocess.run(['pdftotext', '-layout', '-f', '10', '-l', '15', PDF_PATH, '-'], capture_output=True, text=True)
    lines = toc_out.stdout.splitlines()

    studies = []
    current_sec = None
    current_mod = 'RADIOGRAPH'

    for line in lines:
        stripped = line.strip()
        if not stripped: continue
        
        # Check if section header
        if stripped in SEC_MAP:
            current_sec = SEC_MAP[stripped]
            continue
        elif 'WORKFLOW' in stripped:
            # Skip workflow optimization chapters
            current_sec = None
            continue
            
        if current_sec is None:
            continue
            
        m_mod = re.match(r'^\s*(\d+\.\s+[A-Za-z\s\(\)/]+?)\s+\d+$', line)
        if m_mod:
            current_mod = clean_modality(m_mod.group(1).strip())
            continue
            
        m_study = re.search(r'■\s*(.+?)\s+(\d{1,3})$', line)
        if m_study:
            title = clean_title(m_study.group(1).strip())
            book_page = int(m_study.group(2))
            if title.lower() in MANUAL_MAP:
                pdf_page = MANUAL_MAP[title.lower()]
            else:
                est_page = book_page + 17
                clean_t = re.sub(r'\(.*?\)', '', title).strip().lower()
                clean_t = clean_t.replace('1-123', 'i-123').replace('f18', 'fl 8').replace('n eek', 'neck')
                found_p = None
                search_range = range(max(17, est_page - 5), min(len(pages), est_page + 15))
                for p in search_range:
                    p_text = pages[p-1].lower()
                    if clean_t in p_text[:500] or (title.lower() in p_text[:500]):
                        found_p = p
                        break
                if not found_p:
                    for p in range(17, len(pages)):
                        p_text = pages[p-1].lower()
                        if clean_t in p_text[:500]:
                            found_p = p
                            break
                pdf_page = found_p
            studies.append({'section': current_sec, 'modality': current_mod, 'title': title, 'book_page': book_page, 'start_page': pdf_page})

    for i in range(len(studies) - 1):
        next_start = studies[i+1]['start_page']
        studies[i]['end_page'] = next_start - 1 if next_start > studies[i]['start_page'] else studies[i]['start_page']
    studies[-1]['end_page'] = 355
    return studies

def parse_and_refine_study(start_p, end_p):
    res = subprocess.run(['pdftotext', '-layout', '-f', str(start_p), '-l', str(end_p), PDF_PATH, '-'], capture_output=True, text=True)
    lines = res.stdout.splitlines()
    raw_items = []
    current = None
    started = False

    for line in lines:
        if re.match(r'^\s*(?:an\s+)?abbreviated\s+(?:general\s+)?checklist\b', line, re.IGNORECASE):
            break
        stripped = strip_banner_text(line)
        if not stripped:
            continue

        m1 = re.match(r'^\s{0,7}(\d+)\.\s+(.*)', line)
        if m1 and not started:
            started = True
        if not started:
            continue

        m2 = re.match(r'^\s{6,15}([a-z])\.\s+(.*)', line)
        m3 = re.match(r'^\s{14,24}([ivx]+|1[ivx]*|1{1,3}|\d+)\.\s+(.*)', line, re.IGNORECASE)
        m4 = re.match(r'^\s{24,40}([ivx]+|\d+|[a-z])\.\s+(.*)', line, re.IGNORECASE)

        if m4:
            if current: raw_items.append(current)
            current = {'lvl': 4, 'text': [m4.group(2).strip()]}
        elif m3:
            if current: raw_items.append(current)
            current = {'lvl': 3, 'text': [m3.group(2).strip()]}
        elif m2:
            if current: raw_items.append(current)
            current = {'lvl': 2, 'text': [m2.group(2).strip()]}
        elif m1:
            if current: raw_items.append(current)
            current = {'lvl': 1, 'text': [m1.group(2).strip()]}
        elif current:
            current['text'].append(stripped)

    if current: raw_items.append(current)

    # 1. Identify dropped level 1 prefixes
    dropped_l1_indices = set()
    l1_counter = 0
    for it in raw_items:
        if it['lvl'] == 1:
            l1_counter += 1
            full_title = ' '.join(it['text'])
            if is_meta(full_title):
                dropped_l1_indices.add(l1_counter)

    # 2. Filter items and clean telegraphic
    kept_items = []
    current_l1_idx = 0

    for it in raw_items:
        if it['lvl'] == 1:
            current_l1_idx += 1
            if current_l1_idx in dropped_l1_indices:
                continue
        elif current_l1_idx in dropped_l1_indices:
            continue

        full_text = ' '.join(it['text'])
        if is_rhetorical(full_text):
            continue
        if is_subitem_meta(full_text):
            continue

        cleaned = clean_telegraphic(full_text)
        if not cleaned or len(cleaned) < 3:
            continue

        atoms = split_atoms(cleaned)
        depth = it['lvl']
        for atom in atoms:
            if is_rhetorical(atom) or is_subitem_meta(atom):
                continue
            kept_items.append({'orig_depth': depth, 'text': atom})

    # 3. Build tree and renumber
    tree = []
    current_l1 = None
    current_l2 = None
    current_l3 = None

    for it in kept_items:
        d = it['orig_depth']
        text = it['text']
        if d == 1:
            current_l1 = {'text': text, 'children': []}
            tree.append(current_l1)
            current_l2 = None
            current_l3 = None
        elif d == 2:
            if current_l1 is None:
                current_l1 = {'text': 'Primary structures', 'children': []}
                tree.append(current_l1)
            current_l2 = {'text': text, 'children': []}
            current_l1['children'].append(current_l2)
            current_l3 = None
        elif d == 3:
            target = current_l2 if current_l2 is not None else current_l1
            if target is None:
                current_l1 = {'text': 'Primary structures', 'children': []}
                tree.append(current_l1)
                target = current_l1
            current_l3 = {'text': text, 'children': []}
            target['children'].append(current_l3)
        elif d >= 4:
            target = current_l3 if current_l3 is not None else (current_l2 if current_l2 is not None else current_l1)
            target['children'].append({'text': text, 'children': []})

    output = []
    for idx1, n1 in enumerate(tree, 1):
        output.append(f"{idx1}. {n1['text']}")
        for idx2, n2 in enumerate(n1['children'], 1):
            output.append(f"{idx1}.{idx2} {n2['text']}")
            for idx3, n3 in enumerate(n2['children'], 1):
                output.append(f"{idx1}.{idx2}.{idx3} {n3['text']}")
                for idx4, n4 in enumerate(n3['children'], 1):
                    output.append(f"{idx1}.{idx2}.{idx3}.{idx4} {n4['text']}")

    return output

def build_all():
    studies = get_study_list()
    print(f'Compiling {len(studies)} imaging studies...')

    # Load CXR pilot
    with open(PILOT_CXR_PATH, 'r') as f:
        cxr_lines = [line.rstrip() for line in f if line.strip()]

    output_lines = []

    for idx, s in enumerate(studies):
        header = f"{s['section']} > {s['modality']} > {s['title'].upper()}"

        if s['title'].lower() == 'chest radiograph':
            output_lines.append(header)
            for l in cxr_lines:
                if l.startswith('CHEST>'):
                    continue
                output_lines.append(l)
            output_lines.append('')
        else:
            items = parse_and_refine_study(s['start_page'], s['end_page'])
            if items:
                output_lines.append(header)
                output_lines.extend(items)
                output_lines.append('')
            else:
                print(f"WARNING: No items found for {header}")

    with open(OUTPUT_TXT_PATH, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    print(f"\nSuccessfully written to {OUTPUT_TXT_PATH}")
    print(f"Total lines: {len(output_lines)}")

if __name__ == '__main__':
    build_all()
