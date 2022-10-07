import re

def process_chord(chord):
    match = re.match('(.*):......', chord)
    if match:
        return match.group(1)
    return chord

def make_chord_list(line):
    return [(match.start(), process_chord(match.group()))
            for match in re.finditer('[^ ]+', line)]

"""
def chordiness(hmm):
    if not hmm[0] in 'ABCDEFG':
        return 0.

    if '/' in hmm:
        return 1.

    return 0.8/len(hmm)
"""

def id_line(line):
    space_lens = map(len, re.split('[^ ]*', line))
    if sum(space_lens) == 0:
        return 'blank'
    else:
        avg = sum(space_lens)/(len(space_lens)-1)
        if avg > 2:
            return 'chords'
        else:
            return 'lyrics'

def split_string_at_positions(string, positions):
    # note: always returns a list of len(positions)+1 strings
    # (with spaces past the end of the string)
    split = []
    last_pos = 0
    for pos in positions:
        split.append(string[last_pos:pos] + (' ' if pos > len(string) else ''))
        last_pos = pos
    split.append(string[last_pos:] + (' ' if last_pos >= len(string) else ''))
    return split

def LaTeX_chord(chord):
    return '\\[%s]' % chord

def chords_into_lyrics(chords, line):
    split = split_string_at_positions(line, (chord[0] for chord in chords))
    return "".join(sum([[lyric, LaTeX_chord(chord[1])]
                for (lyric, chord) in zip(split, chords)], []) + [split[-1]])

def process_text(text):
    lines = text.split('\n')
    out = ''
    last_chords = None
    
    for line in lines:
        id = id_line(line)
        if id == 'blank':
            out += ((chords_into_lyrics(last_chords, '') + '\n\n')
                    if last_chords else '\n')
            last_chords = None
        elif id == 'chords':
            out += ((chords_into_lyrics(last_chords, '') + '\n')
                    if last_chords else '')
            last_chords = make_chord_list(line)
        elif id == 'lyrics':
            out += ((chords_into_lyrics(last_chords, line) if last_chords else line)
                    + '\n')
            last_chords = None
    if last_chords:
        out += chords_into_lyrics(last_chords, '') + '\n'
    return out
    


test = """


8. If You Don't Cry

INTRO, INTERLUDE: C:032010, G:320033, F:133211, C, F, G

            C        G          Dm:x00231  Em:022000
Softly the crystals falling on 17th       Street

          Am:002210 F           G
do their dance and die and are gone

Em           C       G           Dm
Millions of crystal balls roll around your feet

    Em            G
and nothing gets done

    C
An hour goes by

            F
She doesn't

                  Dm F         C    G
(C): If you don't cry it isn't love

             Dm F          G                  C
If you don't cry then you just don't feel it deep enough

Dying all day in thousands of little ways
Dancing alone and drinking a lot
Closing the clubs and haunting the cabarets
looking for what
Another five years off your life (C)
A year goes by
She doesn't (C)
"""

print process_text(test)
