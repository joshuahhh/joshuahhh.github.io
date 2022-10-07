from markdown.inlinepatterns import Pattern
from markdown.util import etree
from markdown.extensions import Extension

class SpanPattern(Pattern):
    def __init__ (self):
        Pattern.__init__(self, r'\{\{([^\}]+)\}\}')

    def handleMatch(self, m):
        el = etree.Element("span")
        el.set("class", m.group(2))
        return el

class JoshExtension(Extension):
    def extendMarkdown(self, md, md_globals):
    	span_tag = SpanPattern()
        md.inlinePatterns.add('span', span_tag, '_end')

def makeExtension(configs=None):
    return JoshExtension(configs)
