from typing import List
from flask import Flask, session, send_file, redirect, url_for, request, jsonify
import os
from dataclasses import dataclass
import matplotlib.pyplot as plt
from datetime import datetime, timedelta, timezone
from threading import Lock
from generate import generate_planar_graph
import networkx as nx
import uuid
import random
import io

GRAPH_POINTS = 7
PROBLEM_LIFETIME = timedelta(seconds=20)
PROBLEMS_REQUIRED = 100
NODE_SIZE = 1000
DPI = 400


app = Flask(__name__)
app.secret_key = os.urandom(32)

plt_lock = Lock()
problems_lock = Lock()

@dataclass
class Problem:
    graph: nx.Graph
    file: str
    source: str
    target: str
    generated_at: datetime

    def __del__(self):
        os.unlink(self.file)


problems: dict[str, Problem] = {}

def generate_file_path():
    return f"/tmp/image-{uuid.uuid4()}.png"

def new_session_problem() -> str:
    graph = generate_planar_graph(GRAPH_POINTS)
    with plt_lock:    
        plt.clf()
        nx.draw_planar(graph, node_size=NODE_SIZE, labels={n: n for n in graph.nodes()}, font_family="OCR B")
        path = generate_file_path()
        plt.savefig(path, dpi=DPI)

    source, target = 0, 0

    while source == target:
        try:
            source, target = random.choices(list(graph.nodes), k=2)
            nx.shortest_path(graph, source, target)
        except:
            source, target = 0, 0

    problem = Problem(
        graph=graph,
        file=path,
        source=source,
        target=target,
        generated_at=datetime.now(timezone.utc),
    )

    problem_id = str(uuid.uuid4())
    with problems_lock:
        problems[problem_id] = problem

    session["problem_id"] = problem_id

def session_problem_stale() -> bool:
    if "problem_id" not in session:
        return True

    problem_id = session["problem_id"]

    problem = problems.get(problem_id)
    if problem is None:
        return True
    elif datetime.now(timezone.utc) >= problem.generated_at + PROBLEM_LIFETIME:
        del problems[problem_id]
        return True

    return False


@app.get("/params")
def params():
    if session.get("problem_solved"):
        new_session_problem()
        session["problem_solved"] = False
    elif session_problem_stale():
        new_session_problem()
        session["problemes_solved"] = 0

    with problems_lock:
        problem = problems[session["problem_id"]]
    return jsonify({
        "source": problem.source,
        "target": problem.target,

                    })
@app.get("/image")
def image():
    if session.get("problem_solved"):
        new_session_problem()
        session["problem_solved"] = False
    elif session_problem_stale():
        new_session_problem()
        session["problemes_solved"] = 0

    with problems_lock:
        problem = problems[session["problem_id"]]
    return send_file(
        problem.file,
        mimetype="image/png",
        as_attachment=False,
    )

def is_valid_shorted_path(problem: Problem, path: List[str]) -> bool:
    if len(nx.shortest_path(problem.graph, problem.source, problem.target)) != len(path):
        return False

    if problem.source != path[0] or problem.target != path[-1]:
        return False

    for a, b in zip(path, path[1:]):
        if not problem.graph.has_edge(a, b):
            return False
    return True

@app.post("/submit")
def submit():
    if session_problem_stale():
        new_session_problem()
        session["problem_solve"] = False
        return jsonify({"status": "fail", "reason": "stale problem"}), 403

    path = request.json
    if type(path) != list:
        return jsonify({"status": "fail", "reason": "invalid request"}), 403

    for v in path:
        if type(v) != str:
            return jsonify({"status": "fail", "reason": "invalid request"}), 403
        

    problem_id = session.pop("problem_id")
    with problems_lock:
        if problem_id not in problems:
            return jsonify({"status": "fail", "reason": "stale problem"}), 403
        problem = problems[problem_id]

    if not is_valid_shorted_path(problem, path):
        session["problems_solved"] = 0
        return jsonify({"status": "fail", "reason": "invalid path"}), 403

    session["problem_solved"] = True
    session["problems_solved"] = session.get("problems_solved", 0) + 1

    if session["problems_solved"] >= PROBLEMS_REQUIRED:
        return jsonify({"status": "ok", "flag" : os.getenv("FLAG")}), 200

    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=2112,
        debug=False,
        use_debugger=False,
        use_evalex=False,
        threaded=False,
        processes=1,
    )
