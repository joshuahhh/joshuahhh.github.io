How many four-bead necklaces can you make with black and white beads?

Well, what's a necklace? Is it just a sequence of four beads in a circle? With that interpretation, the answer is $2^4 = 16$:

{{a}} <small class='sidenote'>There are two possibilities for the first bead, then two for the second bead, and so on, giving a total of $2\times2\times2\times2=2^4=16$ possibilities for the full chain.</small>

<script type="text/coffeescript">
r = 20; p = r*0.60
rowSize = 8
kwargs =
  r: r
  beadR: r*0.35
  padding: p
  rowSize: rowSize
  line: false
necklaces = cartesianExp([0...2], 4)
necklacesSvg = d3.select(".a").append("svg").classed("pics", true)
               .attr("width", rowSize * (2 * r + 2 * p))
               .attr("height", Math.ceil(necklaces.length / rowSize) * (2 * r + 2 * p))
necklaceGrid necklacesSvg, necklaces, kwargs
</script>

But we drew these necklaces as circles, probably for a good reason. You can slide beads along a necklace, in effect rotating it. So a necklace that looks like {{nl0011 valign}} can be turned into one that looks like {{nl1001 valign}}, while neither of these can be turned into {{nl0101 valign}}.

<script type="text/coffeescript">
r = 10; p = r*0.60
rowSize = 8
kwargs =
  r: r
  beadR: r*0.35
  padding: p
  line: false
window.f = (id, necklace) ->
  d3.selectAll(id).append("svg")
  .attr("width", 2*r + 2*p)
  .attr("height", 2*r + 2*p)
  .each(-> necklaceBox(@, necklace, kwargs))
window.g = (id, i) ->
  d3.selectAll(id).append("svg")
  .attr("width", 2*r + 2*p)
  .attr("height", 2*r + 2*p)
  .each(-> rotatorBox(@, 4, i, kwargs))
f ".nl0000", [0,0,0,0]
f ".nl0001", [0,0,0,1]
f ".nl0010", [0,0,1,0]
f ".nl0011", [0,0,1,1]
f ".nl0100", [0,1,0,0]
f ".nl0101", [0,1,0,1]
f ".nl0110", [0,1,1,0]
f ".nl0111", [0,1,1,1]
f ".nl1000", [1,0,0,0]
f ".nl1001", [1,0,0,1]
f ".nl1010", [1,0,1,0]
f ".nl1011", [1,0,1,1]
f ".nl1100", [1,1,0,0]
f ".nl1101", [1,1,0,1]
f ".nl1110", [1,1,1,0]
f ".nl1111", [1,1,1,1]

g ".rot0", 0
g ".rot90", 1
g ".rot180", 2
g ".rot270", 3

r = 30; p = r*0.60
kwargs =
  r: r
  beadR: r*0.35
  padding: p
  line: false
window.h = (id, i) ->
  d3.selectAll(id).append("svg")
  .attr("width", 2*r + 2*p)
  .attr("height", 2*r + 2*p)
  .each(-> rotatorBox(@, 4, i, kwargs))

h ".rot0big", 0
h ".rot90big", 1
h ".rot180big", 2
h ".rot270big", 3

</script>

Mathematicians adopt a sort of strange terminology here. They say that the pictures {{nl0011 valign}} and {{nl1001 valign}} represent one and the same necklace. In other words, they are two different *pictures* of the same underlying necklace, in the same way that $\frac{2}{3}$ and $\frac{4}{6}$ are two different *pictures* of the same underlying fraction. This is mostly just a matter of definition. To a mathematician, a **necklace** is a little bead-loop picture, with the caveat that two pictures represent the same necklace if one can be rotated to produce the other.

What we did above was count 2<sup>4</sup> necklace-pictures, rather than the actual underlying necklaces. We overcounted, because some necklaces are represented by more than one picture.

Let's group the 16 pictures above according to their underlying necklace:

{{groups}}

<script type="text/coffeescript">
types = [
  [[0,0,0,0]],
  [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]],
  [[1,1,0,0],[0,1,1,0],[0,0,1,1],[1,0,0,1]],
  [[1,0,1,0],[0,1,0,1]],
  [[0,1,1,1],[1,0,1,1],[1,1,0,1],[1,1,1,0]],
  [[1,1,1,1]]
]
r = 20; p = r*0.60
rowSize = 8
kwargs =
  r: r
  beadR: r*0.35
  padding: [p * 2, p]
  line: false
  orientation: "ver"

spacing = 2*r + 2*p
maxLen = Math.max((x.length for x in types)...)
necklacesSvg = d3.select(".groups").append("svg").classed("pics", true)
               .attr("width", rowSize * spacing)
               .attr("height", maxLen * spacing)
necklaceGrid necklacesSvg, types, kwargs

for i in [1...types.length]
  d3.selectAll(".groups g.primary:not(:first-child)").append("path")
    .attr("d", "M 0 0 L 0 #{maxLen * spacing}")
    .style("stroke", "gray")
    .style("stroke-opacity", 1)
</script>

To be totally clear about what went into this grouping: If one picture can be rotated into another, they should be in the same group. If one picture cannot be rotated into another, they should be in different groups. In that way, we ensure that each group represents a unique underlying necklace, and by counting groups, we will count the underlying necklaces.

There are 6 groups, so that's our final answer: you can make 6 four-bead necklaces with black and white beads.

Getting from our 16 necklace-pictures to our 6 necklaces wasn't easy. It involved an ad-hoc process, sorting through all the pictures, comparing them to one another, and grouping them together. If the groups were all the same size, some $n$, then we could count the number of groups by calculating $16/n$. But they're not equal sizes. Some necklaces have 4 pictures, some have 2 pictures, and some only have one picture. The pattern looks chaotic.

And if we were making necklaces out of three colors of bead instead of two colors, or six beads long instead of four beads long, the number of pictures would increase dramatically. Putting them into groups, like we did above, would be a tedious, obnoxious, error-prone process. And although we would get the numeric answer we were looking for, the process would leave us without any real understanding of what was going on.

Fortunately, that there is a powerful technique that we can use to count the number of necklaces. In fact, this technique reaches far beyond this one problem and gives us insight into a broad range of problems which have to do with counting some objects "up to" some kind of symmetry. The technique goes by many names, but here we will call it **Burnside's lemma**. I will show you

* the deep concepts of "group" and "action" that Burnside's lemma relies upon,
* how the lemma works, and
* how you can use the lemma to solve problems which would be very difficult without it.

## Transforming necklaces

At the heart of the necklace-counting problem is the concept of transforming one picture into another via a *transformation*. We should make clear & precise what we mean by this.

Consider the necklace-picture $N=$ {{nl1000 valign}}. It represents the same necklace as the pictures {{nl0100 valign}}, {{nl0010 valign}}, and {{nl0001 valign}}. Why?

Well, we can rotate $N$ into any of the other pictures. The first comes from a 90&deg;-clockwise rotation, the second from a 180&deg;-clockwise rotation, and the third from a 270&deg;-clockwise rotation.

These rotation transformations are the key to understanding the necklace-counting problem, so we will consider them as objects in their own right. We can notate them with arcs, as {{rot90 valign}}, {{rot180 valign}}, and {{rot270 valign}}. With this notation, we can write equations telling what these rotations do to necklace-pictures. Our convention will be to put a rotation before the necklace-picture it acts on, like the $f(x)$ function notation:

{{rot90 valign}} {{nl1000 valign}} = {{nl0100 valign}} <br/>
{{rot180 valign}} {{nl1000 valign}} = {{nl0010 valign}} <br/>
{{rot270 valign}} {{nl1000 valign}} = {{nl0001 valign}}

We're building an algebra of rotations and necklace-pictures! Nice. In fact, we can make a whole multiplication table, which shows what happens when apply any rotation to any necklace-picture:

{{action}}

<script type="text/coffeescript">
drawActionTable(".action", necklacesWithSymmetry(4, 2, 0))
</script>

This table encodes everything there is to know about how necklaces rotate into one another. And it contains key information to solve our counting problem. See, the column below a necklace-picture shows every other picture that represents the same underlying necklace. Let's re-order the columns, so that necklace-pictures representing the same necklace are next to each other horizontally:

{{action2}}

<script type="text/coffeescript">
window.groupedNecklaces = [
  [[0,0,0,0]],
  [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]],
  [[1,1,0,0],[0,1,1,0],[0,0,1,1],[1,0,0,1]],
  [[1,0,1,0],[0,1,0,1]],
  [[0,1,1,1],[1,0,1,1],[1,1,0,1],[1,1,1,0]],
  [[1,1,1,1]]
]
drawActionTable(".action2", window.groupedNecklaces, {drawFixedPoints: false})
</script>

Some order is beginning to emerge from the top table's chaos. Nowhere in this table are the groups mixed up with each other. Taking a picture from one group and rotating it always gives some other picture in the same group. You could imagine breaking the table up into separate tables for each group, each its own little world:

{@style=width:200%;font-size:600%} {{action3_1 tableInlineBlock}} &nbsp; {{action3_2 tableInlineBlock}} &nbsp; {{action3_3 tableInlineBlock}} &nbsp; &hellip;

<script type="text/coffeescript">
drawActionTable(".action3_1", window.groupedNecklaces[0], {drawFixedPoints: false})
drawActionTable(".action3_2", window.groupedNecklaces[1], {drawFixedPoints: false})
drawActionTable(".action3_3", window.groupedNecklaces[2], {drawFixedPoints: false})
</script>

I mentioned near the start of this article how counting the number of groups was tricky because the groups were different sizes. (If they were all the same size, we could just count the number of necklace-pictures and then divide by the group size.) Let's take a closer look at the groups and see if we can find any patterns that tell us about their sizes.

It looks like the groups have size 1, 2, and 4. Let's take a sample group of each size to see how they work:

{@style=width:200%;font-size:350%;vertical-align:top} A: {{action4_1 tableInlineBlock}} &nbsp; B: {{action4_2 tableInlineBlock}} &nbsp; C: {{action4_3 tableInlineBlock}}

<script type="text/coffeescript">
drawActionTable(".action4_1", window.groupedNecklaces[0], {drawFixedPoints: false})
drawActionTable(".action4_2", window.groupedNecklaces[3], {drawFixedPoints: false})
drawActionTable(".action4_3", window.groupedNecklaces[1], {drawFixedPoints: false})
</script>

Group **A** consists of only one necklace-picture: the one with all black beads. The table shows that, no matter how you rotate this picture, you just get the same picture back again. That's why it's alone in its group -- there's no alternate picture you can turn it into through rotation.

Group **C** consists of four necklace-pictures: all the pictures with exactly one white bead. This shows an opposite situation. If you take a picture in this group and rotate it, you will *always* get back a different picture, unless, of course, you applied a 0&deg; rotation. That's why there are four pictures in this group -- one picture for each kind of rotation.

Group **B** consists of two necklace-pictures: the two which alternate white and black beads. This shows a situation between groups **A** and **C**. If you take a picture in this group and rotate it, you will get the same picture back again half the time, and half the time you will get the other picture in the group. That's why there are two pictures in this group.

## Formal interlude

It is useful at this point to introduce some terminology from the world of Real Math&#8482;. The transformations {{rot0 valign}}, {{rot90 valign}}, {{rot180 valign}}, and {{rot180 valign}}, taken as a collection, form what is (confusingly) called a <i>group</i>. Mathematicians study the algebra of transformations like this in the field called <i>group theory</i>.

To solve our counting problem, we care about more than just the group of transformations $\mathbf{G}$. We care how these transformations act on our necklace pictures. If we call the set of necklace pictures $\mathbf{X}$.

## Symmetry and fixed points

Fundamentally, what we are talking about here is *symmetry*. The necklace in group **A** is maximally symmetric -- every way you rotate it, you get back what you started with. The necklaces in group **C** are maximally asymmetric -- there are no rotations that bring them back to themselves (except the 0&deg; rotation). And the necklaces in group **B** are somewhere in-between -- some rotations bring you back to the starting picture, and some don't.

The more symmetric a picture is, the smaller its group will be. The less symmetric a picture is, the bigger its group will be.

We can capture this concept of symmetry by looking at *fixed points* in the table. These are places where a rotation applied to a picture gives back the picture we started with. Here are our three sample groups, with fixed points shaded in:

{@style=width:200%;font-size:350%;vertical-align:top} A: {{action5_1 tableInlineBlock}} &nbsp; B: {{action5_2 tableInlineBlock}} &nbsp; C: {{action5_3 tableInlineBlock}}

<script type="text/coffeescript">
drawActionTable(".action5_1", window.groupedNecklaces[0], {drawFixedPoints: true})
drawActionTable(".action5_2", window.groupedNecklaces[3], {drawFixedPoints: true})
drawActionTable(".action5_3", window.groupedNecklaces[1], {drawFixedPoints: true})
</script>

This shows a remarkable pattern. Each group has the same number of fixed points! They are distributed different ways, from group to group.
<ul>
<li>Group **A** has four fixed points, because it is highly symmetric. There is only one picture, but each of the four rotations make a fixed point for it.</li>
<li>Group **C** has four fixed points, because it is highly asymmetric. Each picture only gets one fixed point -- the obvious 0&deg; one, but its asymmetry means there are four pictures in the group, the largest number possible.</li>
<li>Group **B** has four fixed points. Its intermediate level of symmetry means each picture has two fixed points, and there are two pictures.</li>
</ul>

Here is the full table, with the fixed-point multiplications marked:

{{fixed-points}}

<script type="text/coffeescript">
drawActionTable(".fixed-points", window.groupedNecklaces, {drawFixedPoints: true})
</script>

Now we know that each group leaves its mark on this table in a very precise way -- each group makes four fixed points. We can leave off the lines marking the group structure:

{{fixed-points-no-lines}}

<script type="text/coffeescript">
flatNecklaces = [].concat window.groupedNecklaces...
drawActionTable(".fixed-points-no-lines", flatNecklaces, {drawFixedPoints: true})
</script>

or even go back to our original, group-ignorant column order:

{{fixed-points-no-groups}}

<script type="text/coffeescript">
flatNecklaces = [].concat window.groupedNecklaces...
drawActionTable(".fixed-points-no-groups", necklacesWithSymmetry(4, 2, 0), {drawFixedPoints: true})
</script>

and we can *still* extract the number of groups by counting the number of fixed points, and dividing by four! This is fantastic -- we've come up with a mechanical process to count the number of groups without going through and comparing the pictures to each other pair by pair. Just make the table (see above), mark the fixed points (see above), count them up (24), and divide by four (6). Fantastic.

But it gets even better.

## Counting fixed points

A mechanical process is a great thing to have. For instance, if I asked you how many necklaces were made of six beads each (black and white), you could make a table, count the fixed points, divide that by six, and answer my question without having to put any real thought into the matter.

But that table would have $2^6=64$ columns in it, so your process would take a fair amount of time. And if I asked you how many necklaces were made of six beads, using *three* different colors (say, black, white, and red), you would have $3^6=729$ columns to grapple with. This manual fixed-point counting is starting to seem unreasonable. You could write a computer program to do the counting for you, but, with a bit of cleverness, we can do far better than that.

Let's look at our fixed-point table again:

{{fixed-points-no-groups-2}}

<script type="text/coffeescript">
drawActionTable(".fixed-points-no-groups-2", necklacesWithSymmetry(4, 2, 0), {drawFixedPoints: true})
</script>

We want to count the number of shaded cells in this table. So far, we've done that by sorting the columns into groups, and counting by groups. But what if, instead of counting by columns, we counted by rows? Can we come up with some way of counting how many fixed points occur in a given row?

Each row corresponds to some rotation transformation. The first is rotation by $\frac{0}{4}360^\circ = 0^\circ$, the second is rotation by $\frac{1}{4}360^\circ = 90^\circ$, and so on. Let's call the first one $R_0$, the second $R_1$, and so on, so $R_k$ is rotation by $\frac{k}{4}360^\circ$. We want to know -- how many necklace-pictures get sent to themselves when rotated by $R_k$, for each $k$?

<div style="float:left;clear:both"><span class="rot0big"/></div>
<div style="margin-left:120px">
<p>$R_0$ is easy. Every picture gets sent to itself under a 0&deg; rotation:</p>

<p><b>Fixed point count:</b> $2^4=16$
<br/>
<span class="nl0000 valign"/><span class="nl0001 valign"/><span class="nl0010 valign"/><span class="nl0011 valign"/><span class="nl0100 valign"/><span class="nl0101 valign"/><span class="nl0110 valign"/><span class="nl0111 valign"/><span class="nl1000 valign"/><span class="nl1001 valign"/><span class="nl1010 valign"/><span class="nl1011 valign"/><span class="nl1100 valign"/><span class="nl1101 valign"/><span class="nl1110 valign"/><span class="nl1111 valign"/></p>
</div>

<hr style="clear:both"/>

<div style="float:left;clear:both"><span class="rot90big"/></div>
<div style="margin-left:120px">
$R_1$ is a 90&deg; rotation. What does a fixed point of $R_1$ look like? Well, it's a necklace picture which is sent to itself by a 90&deg; (clockwise) rotation.

<script type="text/coffeescript">
window.kwargs =
  ringR: 40
  midR: 20
  beadR: 10
kwargs.outerR = kwargs.ringR + kwargs.beadR + 5
</script>

<p>
<table>
<tr>
<td><script type="text/coffeescript" id="kjfkdjfdkfj">
svg = getParent('#kjfkdjfdkfj').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
</script></td>
<td style="vertical-align:middle;padding-left:20px">If the top bead is some color $a$,</td>
</tr>
<tr>
<td><script type="text/coffeescript" id="ufhbvfu">
svg = getParent('#ufhbvfu').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 1, 20)
  .text(1, 'a')
</script></td>
<td style="vertical-align:middle;padding-left:20px">then the right bead must be the same color $a$, because the top bead rotates onto the right bead under $R_1$.</td>
</tr>
<tr>
<td><script type="text/coffeescript" id="a48gy2984">
svg = getParent('#a48gy2984').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 1, 20)
  .text(1, 'a')
  .arc(1, 2, 20)
  .text(2, 'a')
</script></td>
<td style="vertical-align:middle;padding-left:20px">Then, since the right bead is the color $a$, the bottom bead must be the color $a$,</td>
</tr>
<tr>
<td><script type="text/coffeescript" id="kcjhboeu">
svg = getParent('#kcjhboeu').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 1, 20)
  .text(1, 'a')
  .arc(1, 2, 20)
  .text(2, 'a')
  .arc(2, 3, 20)
  .text(3, 'a')
  .arc(3, 4, 20, dashed: true)
</script></td>
<td style="vertical-align:middle;padding-left:20px">and so on.</td>
</tr>
</table>
</p>

<p>So, to choose a fixed point of $R_1$, you only have one color choice -- pick $a$, and everything else is determined by the fact that your necklace picture must be sent to itself by $R_1$. Hence, there are $2^1 = 2$ fixed points of $R_1$.</p>

<p><b>Fixed point count:</b> $2^1 = 2$
<br/>
<span class="nl0000 valign"/><span class="nl1111 valign"/></p>

</div>

<hr style="clear:both"/>

<div style="float:left;clear:both"><span class="rot180big"/></div>
<div style="margin-left:120px">

<p>$R_2$ is a 180&deg; rotation. What does a fixed point of $R_2$ look like?</p>

<p>
<table>
<tr>
<td><script type="text/coffeescript" id="vcvhcoi">
svg = getParent('#vcvhcoi').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
</script></td>
<td style="vertical-align:middle;padding-left:20px">If the top bead is some color $a$,</td>
</tr>
<tr>
<td><script type="text/coffeescript" id="iogboweio">
svg = getParent('#iogboweio').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 2, 10, flipped: true)
  .text(2, 'a')
  .arc(2, 4, 10, dashed: true, flipped: true)
</script></td>
<td style="vertical-align:middle;padding-left:20px">then the <i>bottom</i> bead must be the same color $a$, because the top bead rotates onto the bottom bead under $R_2$.</td>
</tr>
</table>
</p>

This is a different situation than we had with $R_1$. The choice of a top color determines the bottom color, but that's all. We still have freedom to choose the right color as we please:

<p>
<table>
<tr>
<td><script type="text/coffeescript" id="dkgjheiog">
svg = getParent('#dkgjheiog').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 2, 10, flipped: true)
  .text(2, 'a')
  .arc(2, 4, 10, dashed: true, flipped: true)
  .text(1, 'b')
</script></td>
<td style="vertical-align:middle;padding-left:20px">If the right bead is some color $b$,</td>
</tr>
<tr>
<td><script type="text/coffeescript" id="ovihoeiwhow">
svg = getParent('#ovihoeiwhow').append("svg")
  .attr("width", 2 * kwargs.outerR)
  .attr("height", 2 * kwargs.outerR)
drawRotDiagram(svg, 4, kwargs)
  .text(0, 'a')
  .arc(0, 2, 10, flipped: true)
  .text(2, 'a')
  .arc(2, 4, 10, dashed: true, flipped: true)
  .text(1, 'b')
  .arc(1, 3, 10, flipped: true)
  .text(3, 'b')
  .arc(3, 5, 10, dashed: true, flipped: true)
</script></td>
<td style="vertical-align:middle;padding-left:20px">then the <i>left</i> bead must be the same color $a$, because the top bead rotates onto the bottom bead under $R_2$.</td>
</tr>
</table>
</p>

<p>To choose a fixed point of $R_2$, you have two color choices -- pick $a$ and $b$, and everything else is determined. Hence, there are $2^2 = 4$ fixed points of $R_2$.</p>

<p><b>Fixed point count:</b> $2^2 = 2$
<br/>
<span class="nl0000 valign"/><span class="nl0101 valign"/><span class="nl1010 valign"/><span class="nl1111 valign"/></p>

</div>

<hr style="clear:both"/>

<div style="float:left;clear:both"><span class="rot270big"/></div>
<div style="margin-left:120px">

<p>$R_3$ is a 270&deg; rotation. This is really the same thing as a 90&deg; rotation in the other direction, though, so ultimately, the situation for $R_3$ is the same as $R_1$.</p>

<p><b>Fixed point count:</b> $2^1 = 2$
<br/>
<span class="nl0000 valign"/><span class="nl1111 valign"/></p>

</div>

Let's count these up: We have $2^4 + 2^1 + 2^2 + 2^1 = 24$ fixed points in total. There are four fixed points per picture-group, so there are $\frac{24}{4} = 6$ underlying necklaces, as we showed above.

So far, this is just an especially tedious derivation of something we already knew, but here's the payoff. Suppose we had $k$ colors, rather than 2. Any $k$. Then the derivation above, in terms of counting "free color choices", applies just as well to $k$ as it does to 2. So the total number of fixed points is $k^4 + k^1 + k^2 + k^1 = k^4 + k^2 + 2k$, so the total number of underlying necklaces is $\frac{1}{4}\left(k^4 + k^2 + 2k\right)$.

For the first time, we have a totally general formula:
> You can make $\frac{1}{4}\left(k^4 + k^2 + 2k\right)$ four-bead necklaces if there are $k$ colors to choose from.

Let's check this. If $k=3$, this gives us a count of $24$. I'll do the grouping for you&hellip;

{{groups4_3a}} {{groups4_3b}}

<script type="text/coffeescript">
typesA = [
  [[0,0,0,0]],
  [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]],
  [[2,0,0,0],[0,2,0,0],[0,0,2,0],[0,0,0,2]],
  [[1,1,0,0],[0,1,1,0],[0,0,1,1],[1,0,0,1]],
  [[1,2,0,0],[0,1,2,0],[0,0,1,2],[2,0,0,1]],
  [[2,1,0,0],[0,2,1,0],[0,0,2,1],[1,0,0,2]],
  [[2,2,0,0],[0,2,2,0],[0,0,2,2],[2,0,0,2]],
  [[1,0,1,0],[0,1,0,1]],
  [[1,0,2,0],[0,1,0,2],[2,0,1,0],[0,2,0,1]],
  [[2,0,2,0],[0,2,0,2]],
  [[1,1,1,0],[0,1,1,1],[1,0,1,1],[1,1,0,1]],
  [[1,1,2,0],[0,1,1,2],[2,0,1,1],[1,2,0,1]],
]
typesB = [
  [[1,2,1,0],[0,1,2,1],[1,0,1,2],[2,1,0,1]],
  [[1,2,2,0],[0,1,2,2],[2,0,1,2],[2,2,0,1]],
  [[2,1,1,0],[0,1,1,1],[1,0,1,1],[1,1,0,1]],
  [[2,1,2,0],[0,1,1,2],[2,0,1,1],[1,2,0,1]],
  [[2,2,1,0],[0,1,2,1],[1,0,1,2],[2,1,0,1]],
  [[2,2,2,0],[0,1,2,2],[2,0,1,2],[2,2,0,1]],
  [[1,1,1,2],[2,1,1,1],[1,2,1,1],[1,1,2,1]],
  [[1,1,2,2],[2,1,1,2],[2,2,1,1],[1,2,2,1]],
  [[1,2,1,2],[2,1,2,1]],
  [[1,2,2,2],[2,1,2,2],[2,2,1,2],[2,2,2,1]],
  [[1,1,1,1]],
  [[2,2,2,2]],
]

r = 10; p = r*0.60
rowSize = 20
kwargs =
  r: r
  beadR: r*0.35
  padding: [p * 2, p]
  line: false
  orientation: "ver"

spacing = 2*r + 2*p
maxLen = 4
necklacesSvgA = d3.select(".groups4_3a").append("svg").classed("pics", true)
               .attr("width", rowSize * spacing)
               .attr("height", maxLen * spacing)
necklacesSvgB = d3.select(".groups4_3b").append("svg").classed("pics", true)
               .attr("width", rowSize * spacing)
               .attr("height", maxLen * spacing)

necklaceGrid necklacesSvgA, typesA, kwargs
necklaceGrid necklacesSvgB, typesB, kwargs

for i in [1...typesA.length]
  d3.selectAll(".groups4_3a g.primary:not(:first-child)").append("path")
    .attr("d", "M 0 0 L 0 #{maxLen * spacing}")
    .style("stroke", "gray")
    .style("stroke-opacity", 1)
for i in [1...typesB.length]
  d3.selectAll(".groups4_3b g.primary:not(:first-child)").append("path")
    .attr("d", "M 0 0 L 0 #{maxLen * spacing}")
    .style("stroke", "gray")
    .style("stroke-opacity", 1)
</script>

The $3^4 = 81$ necklace pictures fall perfectly into 24 groups, just as the formula predicted. The chaos of symmetry has been tamed.

[Applications: Forte numbers, Fermat's little theorem]

<!-- {{fixed-points-no-groups-test}}

<script type="text/coffeescript">
drawActionTable(".fixed-points-no-groups-test", necklacesWithSymmetry(6, 2, 0), {drawFixedPoints: true})
</script>

 -->

<br/><br/><br/>

<label for="n">n:</label> <input id="n" value="4" min="1" type="number">
<label for="k">k:</label> <input id="k" value="2" min="1" type="number">

{{vis}}

<script type="text/coffeescript">
drawFixedSetTable ".vis", "#n", "#k"
</script>

{@class=copyright}<a href="http://web.mit.edu/joshuah/www">Joshua Horowitz</a>.
