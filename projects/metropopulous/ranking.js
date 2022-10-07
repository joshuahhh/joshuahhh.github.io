var w = 1100,
    h = 550;

var labels = ["2mi", "4mi", "8mi", "16mi"];

// main containers
var svg = d3.select("#chart").append("svg:svg")
            .attr("width", w)
            .attr("height", h)
var graph = svg.append("svg:g")
               .attr("transform", "translate(20, 20)");

// "body" = region parameterized by data coordinates
var graphBody = graph.append("svg:g")
                     .attr("transform", "translate(150, 40)");
var graphBodyW = 300,
    graphBodyH = 450;
// one X scale
var graphBodyX = d3.scale.linear()
                   .domain([0, labels.length-1])
                   .range([0, graphBodyW]);
// two Y scales: one for rank and one for raw pop
var graphBodyYRank = d3.scale.linear()
                       .domain([0, data.length-1])
                       .range([10, graphBodyH-10]);
var graphBodyYPop = function() {
    var smallestPop = d3.min(data.map(function(d) { return d3.min(d.pops); }))
    var largestPop = d3.max(data.map(function(d) { return d3.max(d.pops); }))
    return d3.scale.log()
             .domain([smallestPop, largestPop])
             .range([graphBodyH-10, 10]);} ();
// two corresponding functions returning coordinates
function graphBodyCoordRank(rank, i) {
    return graphBodyX(i) + "," + graphBodyYRank(rank);
}
function graphBodyCoordPop(pop, i) {
    return graphBodyX(i) + "," + graphBodyYPop(pop);
}

// a "city" group contains the line-plot and labels for a single city
var cities = graphBody.selectAll("g.city")
    .data(data)
  .enter().append("svg:g").classed("city", true)
    .on("mouseover", selectCity)
    .on("mouseout", unselectCity);
var cityLabelPad = 15;
cities.append("svg:path")
    .attr("fill", "none")
    .attr("class", function(d, i) {
        return "q" + (d.rankings[d.rankings.length-1]%5);
     })
    .classed("Dark2s", true)
    .attr("d", function(d) {
	return "M" + (-cityLabelPad/2) + "," + graphBodyYRank(d.rankings[0])
             + "L" + d.rankings.map(graphBodyCoordRank).join("L")
             + "L" + (graphBodyX(d.rankings.length-1)+cityLabelPad/2) + ","
             + graphBodyYRank(d.rankings[d.rankings.length-1]);
     });
cities.append("svg:text").classed("city-label", true)
cities.append("svg:text").classed("city-label-2", true)
    .style("text-anchor", "end")
    .attr("transform", function(d) {
       return "translate(" + (-cityLabelPad) + ","
                           + graphBodyYRank(d.rankings[0])
               + ")"; });
cities.selectAll("text")
    .each(function(d) {
	this.classList.add("q" + (d.rankings[d.rankings.length-1]%5));})
    .classed("Dark2f", true)
    .style("font-weight", "bold")
    .text(function(d) { return d.name; })
    .style("dominant-baseline", "central");

var scaleLabelPad = 15;
graphBody.selectAll("line.scale-label")
  .data(labels)
  .enter().append("svg:text").classed("scale-label", true)
    .text(function(d) { return d; })
    .style("text-anchor", "middle")
    .attr("transform", function(d, i) {
       return "translate(" + graphBodyX(i) + ","
                           + (-scaleLabelPad) + ")"; });
graphBody.selectAll("line.scale-rule")
  .data(labels)
  .enter().append("svg:line")
    .classed("scale-rule", true)
    .attr("x1", function(d, i) { return graphBodyX(i); })
    .attr("x2", function(d, i) { return graphBodyX(i); })
    .attr("y1", 0)
    .attr("y2", graphBodyH);
function addCommas(nStr) {
    // this adds commas to a number, as appropriate
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
	x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}
graphBody.selectAll("text.pop-label")
  .data(graphBodyYPop.ticks().filter(function(d) {
          return String(d)[0] == '1' || String(d)[0] == '3'; }))
  .enter().append("svg:text")
    .classed("pop-label", true)
    .text(addCommas)
    .attr("text-anchor", "end")
    .attr("x", -cityLabelPad)
    .attr("y", graphBodyYPop)
    .style("fill-opacity", 0)

var img = svg.append("svg:image")
             .attr("x", graphBodyW+300)
             .attr("y", (h-360)/2)
             .attr("width", 420)
             .attr("height", 360);

var transitionDuration = 400;

function toRaw() {
    svg.selectAll("path")
	.transition().duration(transitionDuration)
	.attr("d", function(d) {
	    return "M" + (-cityLabelPad/2) + "," + graphBodyYPop(d.pops[0])
		+ "L" + d.pops.map(graphBodyCoordPop).join("L")
		+ "L" + (graphBodyX(d.pops.length-1)+cityLabelPad/2) + ","
		+ graphBodyYPop(d.pops[d.pops.length-1]); });
    svg.selectAll("text.city-label")
	.transition().duration(transitionDuration)
	.attr("transform", function(d) {
	    return "translate(" + (graphBodyW + cityLabelPad) + ","
                + graphBodyYPop(d.pops[d.pops.length-1])
		+ ")"; });
    svg.selectAll("text.city-label-2")
	.transition().duration(transitionDuration)
	.style("opacity", 0)
    graphBody.selectAll("text.pop-label")
	.transition().delay(transitionDuration)
	.style("fill-opacity", 1)
}

function toRank() {
    svg.selectAll("path")
	.transition().duration(transitionDuration)
	.attr("d", function(d) {
	    return "M" + (-cityLabelPad/2) + "," + graphBodyYRank(d.rankings[0])
		+ "L" + d.rankings.map(graphBodyCoordRank).join("L")
		+ "L" + (graphBodyX(d.rankings.length-1)+cityLabelPad/2) + ","
		+ graphBodyYRank(d.rankings[d.rankings.length-1]); });
    svg.selectAll("text.city-label")
	.transition().duration(transitionDuration)
	.attr("transform", function(d) {
	    return "translate(" + (graphBodyW + cityLabelPad) + ","
                + graphBodyYRank(d.rankings[d.rankings.length-1])
		+ ")"; });
    svg.selectAll("text.city-label-2")
	.transition().duration(transitionDuration)
	.style("opacity", 1)
    graphBody.selectAll("text.pop-label")
	.transition().delay(0)
	.style("fill-opacity", 0)
}

function selectCity(d, i) {
    cities.filter(function(d2, i2) { return i2 == i; })
	  .classed("selected", true);
    img.attr("xlink:href", "img-" + d.name + "-small.png");
}

function unselectCity(d, i) {
    cities.filter(function(d2, i2) { return i2 == i; })
	  .classed("selected", false);
    img.attr("xlink:href", "");
}

toRank();