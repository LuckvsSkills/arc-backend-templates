# ============================================
# ARC SECURITY — INPUT SANITIZER
# Beschermt tegen XSS, SQL injection en
# gevaarlijke karakters in alle invoer
# ============================================

import re
import html
from typing import Any

# Gevaarlijke SQL patronen
SQL_PATRONEN = [
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|TRUNCATE)\b)",
    r"(--|;|\/\*|\*\/|xp_)",
    r"(\bOR\b\s+\d+\s*=\s*\d+)",
    r"(\bAND\b\s+\d+\s*=\s*\d+)",
    r"('|\"|`)(.*?)\1\s*(=|<|>|LIKE)",
]

# Gevaarlijke HTML/JS patronen
XSS_PATRONEN = [
    r"<script[^>]*>.*?</script>",
    r"javascript\s*:",
    r"on\w+\s*=",
    r"<iframe[^>]*>",
    r"<object[^>]*>",
    r"<embed[^>]*>",
    r"eval\s*\(",
    r"document\.(cookie|write|location)",
    r"window\.(location|open)",
]

# Prompt injection patronen voor AI agents
PROMPT_PATRONEN = [
    r"negeer\s+(je\s+)?(vorige|eerdere|alle)\s+instructies",
    r"ignore\s+(all\s+)?(previous|prior|your)\s+instructions",
    r"(jij bent|you are)\s+(nu|now)\s+",
    r"(nieuwe|new)\s+(rol|role|persona|instructie|instruction)",
    r"(vergeet|forget)\s+(alles|everything|je bent|you are)",
    r"(doe|pretend|act)\s+(alsof|as if|like)\s+",
    r"system\s*:\s*",
    r"<\|?(system|user|assistant|human)\|?>",
    r"\[INST\]|\[\/INST\]",
    r"###\s*(instructie|instruction|system|prompt)",
    r"(overwrite|override|bypass|hack)\s+(the\s+)?(system|prompt|instruction)",
    r"DAN\s+modus|DAN\s+mode|jailbreak",
]

def bevat_sql_injectie(tekst: str) -> bool:
    tekst_upper = tekst.upper()
    for patroon in SQL_PATRONEN:
        if re.search(patroon, tekst_upper, re.IGNORECASE):
            return True
    return False

def bevat_xss(tekst: str) -> bool:
    for patroon in XSS_PATRONEN:
        if re.search(patroon, tekst, re.IGNORECASE | re.DOTALL):
            return True
    return False

def bevat_prompt_injectie(tekst: str) -> bool:
    for patroon in PROMPT_PATRONEN:
        if re.search(patroon, tekst, re.IGNORECASE):
            return True
    return False

def saniteer_tekst(tekst: str, voor_agent: bool = False) -> str:
    if not isinstance(tekst, str):
        return tekst

    # HTML escapen
    tekst = html.escape(tekst)

    # Gevaarlijke karakters verwijderen
    tekst = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', tekst)

    # Script tags volledig verwijderen
    tekst = re.sub(r'<script[^>]*>.*?</script>', '', tekst, flags=re.IGNORECASE | re.DOTALL)

    # Als input naar agent gaat, extra bescherming
    if voor_agent:
        # Speciale prompt karakters neutraliseren
        tekst = tekst.replace('###', '# # #')
        tekst = tekst.replace('<|', '< |')
        tekst = tekst.replace('|>', '| >')
        tekst = re.sub(r'\[INST\]', '[INST_GEBLOKKEERD]', tekst, flags=re.IGNORECASE)

    return tekst.strip()

def saniteer_object(obj: Any, voor_agent: bool = False) -> Any:
    if isinstance(obj, str):
        return saniteer_tekst(obj, voor_agent)
    elif isinstance(obj, dict):
        return {k: saniteer_object(v, voor_agent) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [saniteer_object(item, voor_agent) for item in obj]
    return obj

def valideer_veiligheid(tekst: str, voor_agent: bool = False) -> tuple[bool, str]:
    if bevat_sql_injectie(tekst):
        return False, "Ongeldige invoer gedetecteerd"
    if bevat_xss(tekst):
        return False, "Ongeldige invoer gedetecteerd"
    if voor_agent and bevat_prompt_injectie(tekst):
        return False, "Ongeldige invoer gedetecteerd"
    return True, ""
