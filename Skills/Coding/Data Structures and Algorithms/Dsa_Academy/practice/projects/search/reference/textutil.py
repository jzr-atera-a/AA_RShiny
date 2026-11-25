import re

_TOKEN = re.compile(r"[a-z0-9]+")


def tokenize(text):
    """Maximal runs of ASCII letters / digits, lower-cased. 'snake_case' -> ['snake', 'case']."""
    return _TOKEN.findall(text.lower())
