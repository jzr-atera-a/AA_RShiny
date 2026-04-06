# modules/chapter18.R — Graphs, BFS, DFS, Dijkstra

CH18_QUEUE_PY <- 'class Queue:
    def __init__(self):
        self.data = []
    def enqueue(self, element):
        self.data.append(element)
    def dequeue(self):
        return self.data.pop(0)
    def read(self):
        return self.data[0] if self.data else None'

CH18_VERTEX_PY <- 'class Vertex:
    def __init__(self, value):
        self.value = value
        self.adjacent_vertices = []
    def add_adjacent_vertex(self, vertex):
        self.adjacent_vertices.append(vertex)'

CH18_CITY_PY <- 'class City:
    def __init__(self, name):
        self.name = name
        self.routes = {}
    def add_route(self, city, price):
        self.routes[city] = price'

CH18_FILES <- list(
  list(
    name = "vertex.py",
    description = "<strong>vertex.py</strong> — Directed graph vertex. <code>add_adjacent_vertex</code> adds an outgoing edge from this vertex only.",
    code = 'class Vertex:
    def __init__(self, value):
        self.value             = value
        self.adjacent_vertices = []

    def add_adjacent_vertex(self, vertex):
        self.adjacent_vertices.append(vertex)',
    demo = 'alice   = Vertex("alice")
bob     = Vertex("bob")
cynthia = Vertex("cynthia")
alice.add_adjacent_vertex(bob)
alice.add_adjacent_vertex(cynthia)
bob.add_adjacent_vertex(cynthia)
print(f"alice -> {[v.value for v in alice.adjacent_vertices]}")
print(f"bob   -> {[v.value for v in bob.adjacent_vertices]}")
print(f"cynthia -> {[v.value for v in cynthia.adjacent_vertices]}")'
  ),
  list(
    name = "undirected_graph_vertex.py",
    description = "<strong>undirected_graph_vertex.py</strong> — Undirected vertex. A single <code>add_adjacent_vertex</code> call updates <em>both</em> vertices' adjacency lists.",
    code = 'class Vertex:
    def __init__(self, value):
        self.value             = value
        self.adjacent_vertices = []

    def add_adjacent_vertex(self, vertex):
        self.adjacent_vertices.append(vertex)
        vertex.adjacent_vertices.append(self)',
    demo = 'alice = Vertex("alice")
bob   = Vertex("bob")
carol = Vertex("carol")
alice.add_adjacent_vertex(bob)
bob.add_adjacent_vertex(carol)
print(f"alice: {[v.value for v in alice.adjacent_vertices]}")
print(f"bob:   {[v.value for v in bob.adjacent_vertices]}")
print(f"carol: {[v.value for v in carol.adjacent_vertices]}")'
  ),
  list(
    name = "dfs_traverse.py",
    description = "<strong>dfs_traverse.py</strong> — Depth-First Search traversal. Visits each vertex and recursively explores its unvisited neighbours before backtracking. O(V + E).",
    code = 'def dfs_traverse(vertex, visited_vertices):
    visited_vertices[vertex.value] = True
    print(vertex.value)

    for adjacent_vertex in vertex.adjacent_vertices:
        if not visited_vertices.get(adjacent_vertex.value):
            dfs_traverse(adjacent_vertex, visited_vertices)',
    demo = 'import vertex as v_mod
alice = v_mod.Vertex("Alice")
bob   = v_mod.Vertex("Bob")
candy = v_mod.Vertex("Candy")
derek = v_mod.Vertex("Derek")
fred  = v_mod.Vertex("Fred")
gina  = v_mod.Vertex("Gina")
alice.add_adjacent_vertex(bob)
alice.add_adjacent_vertex(candy)
alice.add_adjacent_vertex(derek)
bob.add_adjacent_vertex(fred)
derek.add_adjacent_vertex(gina)
print("DFS traversal from Alice:")
dfs_traverse(alice, {})'
  ),
  list(
    name = "dfs.py",
    description = "<strong>dfs.py</strong> — DFS that searches for a specific value and returns the vertex when found. Explores deeply before trying siblings. O(V + E).",
    code = 'def dfs(vertex, search_value, visited_vertices):
    visited_vertices[vertex.value] = True

    if vertex.value == search_value:
        return vertex

    for adjacent_vertex in vertex.adjacent_vertices:
        if adjacent_vertex.value == search_value:
            return adjacent_vertex
        if not visited_vertices.get(adjacent_vertex.value):
            result = dfs(adjacent_vertex, search_value, visited_vertices)
            if result:
                return result

    return None',
    demo = 'import vertex as v_mod
alice = v_mod.Vertex("Alice")
bob   = v_mod.Vertex("Bob")
gina  = v_mod.Vertex("Gina")
derek = v_mod.Vertex("Derek")
alice.add_adjacent_vertex(bob)
alice.add_adjacent_vertex(derek)
derek.add_adjacent_vertex(gina)
result = dfs(alice, "Gina", {})
print(f"dfs(alice, Gina)  -> {result.value if result else None}")
print(f"dfs(alice, Jorge) -> {dfs(alice, \"Jorge\", {})}")'
  ),
  list(
    name = "bfs_traverse.py",
    description = "<strong>bfs_traverse.py</strong> — Breadth-First Search traversal. Uses a Queue to visit vertices level by level. Guarantees shortest hop-count ordering. O(V + E).",
    code = 'import queue_implementation

def bfs_traverse(starting_vertex):
    queue = queue_implementation.Queue()
    visited_vertices = {}
    visited_vertices[starting_vertex.value] = True
    queue.enqueue(starting_vertex)

    while queue.read():
        current_vertex = queue.dequeue()
        print(current_vertex.value)

        for adjacent_vertex in current_vertex.adjacent_vertices:
            if not visited_vertices.get(adjacent_vertex.value):
                visited_vertices[adjacent_vertex.value] = True
                queue.enqueue(adjacent_vertex)',
    demo = 'import vertex as v_mod
import queue_implementation
alice = v_mod.Vertex("Alice")
bob   = v_mod.Vertex("Bob")
candy = v_mod.Vertex("Candy")
derek = v_mod.Vertex("Derek")
fred  = v_mod.Vertex("Fred")
gina  = v_mod.Vertex("Gina")
alice.add_adjacent_vertex(bob)
alice.add_adjacent_vertex(candy)
alice.add_adjacent_vertex(derek)
bob.add_adjacent_vertex(fred)
derek.add_adjacent_vertex(gina)
print("BFS traversal (level by level):")
bfs_traverse(alice)'
  ),
  list(
    name = "solution5.py",
    description = "<strong>solution5.py — BFS Shortest Path</strong> — Finds the fewest-hops path between two vertices. Builds a previous-vertex table during BFS, then traces back from destination to source. O(V + E).",
    code = 'import queue_implementation

def shortest_path(first_vertex, second_vertex, visited_vertices):
    queue = queue_implementation.Queue()
    previous_vertex_table = {}
    visited_vertices[first_vertex.value] = True
    queue.enqueue(first_vertex)

    while queue.read():
        current_vertex = queue.dequeue()
        for adjacent_vertex in current_vertex.adjacent_vertices:
            if not visited_vertices.get(adjacent_vertex.value):
                visited_vertices[adjacent_vertex.value] = True
                queue.enqueue(adjacent_vertex)
                previous_vertex_table[adjacent_vertex.value] = current_vertex.value

    path = []
    current_value = second_vertex.value
    while current_value != first_vertex.value:
        path.insert(0, current_value)
        current_value = previous_vertex_table.get(current_value)
    path.insert(0, first_vertex.value)
    return path',
    demo = 'import vertex as v_mod
import queue_implementation
idris = v_mod.Vertex("Idris")
talia = v_mod.Vertex("Talia")
ken   = v_mod.Vertex("Ken")
marco = v_mod.Vertex("Marco")
sasha = v_mod.Vertex("Sasha")
lina  = v_mod.Vertex("Lina")
kamil = v_mod.Vertex("Kamil")
idris.add_adjacent_vertex(talia)
talia.add_adjacent_vertex(idris)
talia.add_adjacent_vertex(ken)
ken.add_adjacent_vertex(marco)
marco.add_adjacent_vertex(sasha)
sasha.add_adjacent_vertex(lina)
lina.add_adjacent_vertex(kamil)
kamil.add_adjacent_vertex(idris)
idris.add_adjacent_vertex(kamil)
path = shortest_path(idris, lina, {})
print(f"Shortest path Idris -> Lina: {path}")'
  ),
  list(
    name = "dijkstra.py",
    description = "<strong>dijkstra.py</strong> — Dijkstra's algorithm for cheapest path in a weighted graph. Greedily expands the cheapest unvisited city, relaxing edge weights. Returns the full path. O(V² + E) with this implementation.",
    code = 'def dijkstra_shortest_path(starting_city, final_destination):
    cheapest_prices_table            = {}
    cheapest_previous_stopover_table = {}
    unvisited_cities                 = [starting_city]
    visited_cities                   = {}

    cheapest_prices_table[starting_city.name] = 0
    current_city = starting_city

    while unvisited_cities:
        visited_cities[current_city.name] = True
        unvisited_cities.remove(current_city)

        for adjacent_city, price in current_city.routes.items():
            if (not visited_cities.get(adjacent_city.name)
                    and adjacent_city not in unvisited_cities):
                unvisited_cities.append(adjacent_city)

            price_through_current = cheapest_prices_table[current_city.name] + price

            if (not cheapest_prices_table.get(adjacent_city.name) or
                    price_through_current < cheapest_prices_table[adjacent_city.name]):
                cheapest_prices_table[adjacent_city.name] = price_through_current
                cheapest_previous_stopover_table[adjacent_city.name] = current_city.name

        cheapest_price = float("inf")
        for city in unvisited_cities:
            if cheapest_prices_table[city.name] < cheapest_price:
                current_city   = city
                cheapest_price = cheapest_prices_table[city.name]

    path              = []
    current_city_name = final_destination.name
    while current_city_name:
        path.insert(0, current_city_name)
        current_city_name = cheapest_previous_stopover_table.get(current_city_name)
    return path',
    demo = 'import city as city_mod
atlanta = city_mod.City("Atlanta")
boston  = city_mod.City("Boston")
chicago = city_mod.City("Chicago")
denver  = city_mod.City("Denver")
el_paso = city_mod.City("El Paso")
atlanta.add_route(denver, 160)
atlanta.add_route(boston, 100)
boston.add_route(chicago, 120)
boston.add_route(denver, 180)
chicago.add_route(el_paso, 80)
denver.add_route(chicago, 40)
denver.add_route(el_paso, 140)
el_paso.add_route(boston, 100)
path = dijkstra_shortest_path(atlanta, el_paso)
print(f"Cheapest path Atlanta -> El Paso:")
print(" -> ".join(path))'
  ),
  list(
    name = "city.py",
    description = "<strong>city.py</strong> — Weighted graph vertex for cities. The <code>routes</code> dict maps City objects to their travel cost — the data model for Dijkstra.",
    code = 'class City:
    def __init__(self, name):
        self.name   = name
        self.routes = {}

    def add_route(self, city, price):
        self.routes[city] = price',
    demo = 'chicago = City("Chicago")
denver  = City("Denver")
boston  = City("Boston")
chicago.add_route(denver, 100)
chicago.add_route(boston, 250)
print("Chicago routes:")
for dest, price in chicago.routes.items():
    print(f"  -> {dest.name}: ${price}")'
  )
)

chapter18_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(18, "🕸️", "Connecting Everything with Graphs",
      "Graphs model any network of relationships — social networks, maps, dependencies, the internet. This chapter covers directed and undirected graphs, Depth-First Search, Breadth-First Search, and Dijkstra's algorithm for weighted shortest paths.",
      c("Directed & Undirected", "DFS O(V+E)", "BFS O(V+E)", "Shortest Path", "Dijkstra's", "Weighted Graphs")),
    stats_row(
      list("O(V+E)", "DFS / BFS"),
      list("O(1)",   "Add edge"),
      list("BFS",    "Fewest hops"),
      list("Dijkstra","Cheapest path")
    ),
    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "🕸️ Graph Fundamentals", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Vertices & Edges"),
                    tags$p("A graph is a set of", tags$strong("vertices (nodes)"), "connected by",
                           tags$strong("edges."), "Unlike trees, graphs can contain cycles and
                           any vertex can connect to any other."),
                    tags$ul(
                      tags$li(tags$strong("Directed:"), " edges have direction (follower → followee)"),
                      tags$li(tags$strong("Undirected:"), " edges are symmetric (friendships)"),
                      tags$li(tags$strong("Weighted:"), " edges carry a numeric cost (distance, price)"),
                      tags$li(tags$strong("Adjacency list:"), " each vertex stores its neighbours")
                    )),
                div(class = "tip-box",
                    HTML("<strong>💡 Real-world graphs:</strong> Social networks, road maps, the
                          internet, compiler dependency graphs, and recommendation systems are
                          all graphs."))
            ),
            box(title = "🔍 DFS vs BFS Side by Side", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th(""), tags$th("DFS"), tags$th("BFS"))),
                  tags$tbody(
                    tags$tr(tags$td("Data structure"), tags$td("Stack (call stack)"), tags$td("Queue")),
                    tags$tr(tags$td("Visit order"),    tags$td("Deep first"),         tags$td("Level by level")),
                    tags$tr(tags$td("Complexity"),     tags$td("O(V + E)"),           tags$td("O(V + E)")),
                    tags$tr(tags$td("Shortest path?"), tags$td("❌ No"),              tags$td("✅ Yes (unweighted)")),
                    tags$tr(tags$td("Best for"),       tags$td("Cycles, topological"), tags$td("Nearest neighbours"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ Rule:</strong> For fewest hops in an unweighted graph, always use BFS.
                          For weighted graphs (different edge costs), use Dijkstra's algorithm."))
            )
          ),
          fluidRow(
            box(title = "🗺️ Dijkstra's Algorithm — Step by Step", status = "success", solidHeader = TRUE, width = 12,
                fluidRow(
                  column(5,
                    div(class = "framework-card",
                        tags$h5("Key Data Structures"),
                        tags$ul(
                          tags$li(tags$code("cheapest_prices_table"), " — lowest known cost to each city"),
                          tags$li(tags$code("cheapest_previous_stopover_table"), " — how we got there (for path reconstruction)"),
                          tags$li(tags$code("unvisited_cities"), " — cities we know about but haven't expanded yet"),
                          tags$li(tags$code("visited_cities"), " — cities fully processed")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("The Loop"),
                        tags$ol(
                          tags$li("Pick cheapest unvisited city"),
                          tags$li("For each neighbour, compute cost via current city"),
                          tags$li("If cheaper than known best, update tables"),
                          tags$li("Mark city visited; repeat")
                        )
                    )
                  ),
                  column(7,
                    div(class = "framework-card",
                        tags$h5("Example — Atlanta to El Paso"),
                        tags$table(class = "algo-table",
                          tags$thead(tags$tr(tags$th("City"), tags$th("Cheapest"), tags$th("Via"))),
                          tags$tbody(
                            tags$tr(tags$td("Atlanta"), tags$td("$0"),   tags$td("start")),
                            tags$tr(tags$td("Boston"),  tags$td("$100"), tags$td("Atlanta")),
                            tags$tr(tags$td("Denver"),  tags$td("$160"), tags$td("Atlanta")),
                            tags$tr(tags$td("Chicago"), tags$td("$200"), tags$td("Denver")),
                            tags$tr(tags$td("El Paso"), tags$td("$280"), tags$td("Chicago"))
                          )
                        ),
                        div(class = "info-box-plain",
                            HTML("<strong>Path:</strong> Atlanta → Denver → Chicago → El Paso ($280) <br>
                                  Beats: Atlanta → Boston → Chicago → El Paso ($300)"))
                    )
                  )
                )
            )
          )
        ),
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 18 — Graphs, DFS, BFS & Dijkstra",
            "Directed and undirected vertices, DFS traversal, DFS search, BFS traversal, BFS shortest path, weighted city vertex, and Dijkstra's algorithm."
          ),
          file_pills_ui(ns, CH18_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter18_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "queue_implementation.py", code = CH18_QUEUE_PY,  description = "", demo = ""),
      list(name = "vertex.py",               code = CH18_VERTEX_PY, description = "", demo = ""),
      list(name = "city.py",                 code = CH18_CITY_PY,   description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH18_FILES, extra))
  })
}
