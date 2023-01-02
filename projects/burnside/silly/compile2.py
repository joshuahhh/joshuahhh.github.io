import markdown
import pyjade
import josh_markdown
import livedep

md = markdown.Markdown(extensions=["extra", josh_markdown.makeExtension()])
# no "nl2br"

def compile_jade(src, global_context={}):
    _parser = pyjade.parser.Parser(src)
    block = _parser.parse()
    _compiler = pyjade.ext.html.HTMLCompiler(block)
    _compiler.global_context = global_context
    return _compiler.compile().strip()

def compile_index_html(markdown_src, jade_src):
    content = md.convert(markdwon_src)

    return compile_jade(jade_src, {"content": content})

def compile_coffeescript(coffeescript_src):
    pass

if __name__ == "__main__":
    subprocess.Popen("coffee -bcw *.coffee", shell=True, stdout=subprocess.PIPE)

    livedep.add_product(
        compile_index_html,
        ['index.markdown', 'index.jade'],
        'index.html')

    livedep.add_product()

    livedep.run()