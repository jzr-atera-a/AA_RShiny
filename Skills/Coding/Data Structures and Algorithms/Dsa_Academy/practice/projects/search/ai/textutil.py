import re


def tokenize(text):
    """Lower-case words, punctuation removed."""
    return re.findall(r"\w+", text.lower())
