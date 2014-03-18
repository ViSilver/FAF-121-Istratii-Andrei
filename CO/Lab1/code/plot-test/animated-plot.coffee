

$ ->

  simulation = new Simulation

  # bind links
  $("#start").click -> simulation.startSimulation()

  $("#stop").click -> simulation.stopSimulation()




class Simulation
  constructor: () ->
    @isRunning = false
    @counter = makeCounter(0.5)

    @spring = new Spring
    @spring.reset(0, 0)

    @graphs = []
    @graphs.push new Graph "graph1", 800, 200, 0.5 # x
    #@graphs.push new Graph "graph2", 800, 200, 0.5 # v
    @graphs.push new Graph "graph3", 800, 200, 0.5 # F(t)

    @paths = []
    @paths.push new Path @graphs[0], "blue"
    @paths.push new Path @graphs[0], "red"
    @paths.push new Path @graphs[1], "blue"

    @anim = new SpringAnimation "spring", 200, 200

  startSimulation: () ->
    console.log "Simulation started"
    that = this
    @process = setInterval((() -> that.simulate()), 100) unless @isRunning
    @isRunning = true

  stopSimulation: () ->
    clearInterval @process
    @isRunning = false
    console.log "Simulation ended"

  resetSimulation: () ->

  simulate: () ->
    t = @counter()

    [x, v] = @spring.next(0.5)

    @paths[0].data.push(x)
    @paths[1].data.push(v)
    @paths[2].data.push(@spring.externalForce(t-0.5))

    for path in @paths
      path.path
        .attr("d", path.lineGenerator(path.data))
        .attr("transform", null)
        .transition()
        .duration(50)
        .ease("linear")
        .attr("transform", "translate(" + @graphs[0].xScale(-1) + ",0)")
      path.data.shift()

      @anim.update(x)



class Graph
  constructor: (graphID, width, height, delta) ->

    n = 100
    margin = {top: 10, right: 20, bottom: 10, left: 20}

    @svg = d3.select("##{graphID}").append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")


    # clipping rect
    @svg.append("defs").append("clipPath")
      .attr("id", "clip")
      .append("rect")
      .attr("width", width)
      .attr("height", height)


    # border
    @svg.append("rect")
      .attr("width", width)
      .attr("height", height)
      .attr("fill", "none")
      .attr("stroke", "black")
      .attr("stroke-width", 0.5)

    @xScale = d3.scale.linear()
      .domain([0, n-1])
      .range([0, width])


    @yScale = d3.scale.linear()
      .domain([-2,2])             # TODO: support changes
      .range([height, 0])


    # x axis
    @svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + @yScale(0) + ")")
      .call(d3.svg.axis().scale(@xScale).orient("bottom").ticks(0))

    # y axis
    @svg.append("g")
      .attr("class", "y axis")
      .call(d3.svg.axis().scale(@yScale).orient("left"))




class Path
  constructor: (graph, color) ->

    n = 100

    @data = []
    @data.push 0 while @data.length < n # init data with zeros

    @lineGenerator = d3.svg.line()
      .x( (d,i) -> graph.xScale(i) )
      .y( (d,i) -> graph.yScale(d) )
      .interpolate("basis")


    @path = graph.svg.append("g")
      .attr("clip-path", "url(#clip)")
      .append("path")
      .attr("d", @lineGenerator(@data))
      .attr("stroke", color)
      .attr("stroke-width", 2)
      .attr("fill", "none")



class Spring
  constructor: (@mass = 1.0, @elasticity = 1.0, @damping = 0.0, @externalForce = ((t) -> 0.0)) ->
    @mass = 0.1
    @elasticity = 0.0
    @damping = 0.2
    @externalForce = (t) -> 0.3*Math.cos(t*3.0)

  reset: (x0, v0) ->
    @t = 0.0
    @x = x0
    @v = v0


  next: (delta) ->
    m = @mass
    k = @elasticity
    c = @damping
    f = @externalForce
    f1 = (t, ys) -> ys[1]
    f2 = (t, ys) -> (f(t) - c*ys[1] - k*ys[0])/m

    [@x, @v] = rk4([f1, f2], delta, @t, [@x, @v])
    @t += delta
    [@x, @v]


makeCounter = (delta) ->
  t = 0
  () ->
    r = t
    t += delta
    r


rk4 = (fs, h, t, ys) ->
  vectorSum = (v1, v2) ->
    res = []
    res.push(v1[i] + v2[i]) for v, i in v1
    res
  scalarMul = (v, a) -> v.map((x)->x*a)

  h2 = 0.5 * h
  k1 = fs.map( (f) -> f(t, ys) )
  k2 = fs.map( (f) -> f(t + h2, vectorSum(ys, scalarMul(k1,h2))) )
  k3 = fs.map( (f) -> f(t + h2, vectorSum(ys, scalarMul(k2,h2))) )
  k4 = fs.map( (f) -> f(t + h, vectorSum(ys, scalarMul(k3,h))) )
  u = scalarMul(k2, 2)
  v = scalarMul(k3, 2)
  w = vectorSum(vectorSum(vectorSum(k1, u), v), k4)  # inefficient but should work
  vectorSum(ys, scalarMul(w, (1/6.0)*h))



class SpringAnimation
  constructor: (graphID, width, height) ->
    margin = {top: 20, right: 20, bottom: 20, left: 20}

    @svg = d3.select("##{graphID}").append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")


    # clipping rect
    @svg.append("defs").append("clipPath")
      .attr("id", "clip")
      .append("rect")
      .attr("width", width)
      .attr("height", height)


    # border
    @svg.append("rect")
      .attr("width", width)
      .attr("height", height)
      .attr("fill", "none")
      .attr("stroke", "black")
      .attr("stroke-width", 0.5)

    @xScale = d3.scale.linear()
      .domain([0, 10])
      .range([0, width])

    @yScale = d3.scale.linear()
      .domain([0, 10])             # TODO: support changes
      .range([0, height])

    

    @lineGenerator = d3.svg.line()
      .x( (d) -> @xScale(d[0]) )
      .y( (d) -> @yScale(d[1]) )

    ###
    @data = [
      {x: 5, y: 0},
      {x: 5, y: 0.75},
      {x: 4, y: 1},
      {x: 6, y: 1.5},
      {x: 4, y: 2},
      {x: 6, y: 2.5},
      {x: 4, y: 3},
      {x: 6, y: 3.5},
      {x: 4, y: 4},
      {x: 5, y: 4.25}
      {x: 5, y: 6},
    ]
    ###

    @initData = [
      [5, 0],
      [5, 0.75],
      [4, 1],
      [6, 1.5],
      [4, 2],
      [6, 2.5],
      [4, 3],
      [6, 3.5],
      [4, 4],
      [5, 4.25],
      [5, 6]
    ]



    @path = @svg.append("g")
      .attr("clip-path", "url(#clip)")
      .append("path")
      .attr("d", @lineGenerator(@initData))
      .attr("stroke", "blue")
      .attr("stroke-width", 2)
      .attr("fill", "none")


    @circle = @svg.append("circle")
      .attr("cx", @xScale(5))
      .attr("cy", @yScale(6))
      .attr("r", 20)


  update: (delta) ->
    @circle.transition()
        .duration(50)
        .ease("linear")
        .attr("transform", "translate(0, " + (@yScale(delta*2)) + ")")

    @data = @initData.map( (p) ->
      [x, y] = p
      [x, (y + 2*delta*(y/6.0))]
    )

    @path.transition()
      .duration(50)
      .ease("linear")
      .attr("d", @lineGenerator(@data))