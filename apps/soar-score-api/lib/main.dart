import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final Logger _logger = Logger("score-soar-api");

// In-memory store for contests
final Map<String, Map<String, dynamic>> contests = {};
int nextId = 1;

Future<Response> getHealth(Request request) async {
  return Response(200, body: jsonEncode({"status": "healthy", "timestamp": DateTime.now().toIso8601String()}));
}

Future<Response> getContests(Request request) async {
  final list = contests.values.map((c) => {
    "id": c["id"],
    "name": c["name"],
    "location": c["location"],
    "date": c["date"],
    "status": c["status"]
  }).toList();
  return Response(200, body: jsonEncode({"contests": list}));
}

Future<Response> getContest(Request request, String id) async {
  final contest = contests[id];
  if (contest == null) {
    return Response(404, body: jsonEncode({"error": "not_found"}));
  }
  return Response(200, body: jsonEncode({"contest": contest}));
}

Future<Response> createContest(Request request) async {
  final body = jsonDecode(await request.readAsString());
  final id = nextId.toString();
  contests[id] = {
    "id": id,
    "name": body["name"],
    "location": body["location"],
    "date": body["date"],
    "status": "active"
  };
  nextId++;
  _logger.info("Created contest: $id");
  return Response(201, body: jsonEncode({"contest": contests[id]}));
}

Future<Response> updateContest(Request request, String id) async {
  final contest = contests[id];
  if (contest == null) {
    return Response(404, body: jsonEncode({"error": "not_found"}));
  }
  final body = jsonDecode(await request.readAsString());
  if (body["name"] != null) contest["name"] = body["name"];
  if (body["location"] != null) contest["location"] = body["location"];
  if (body["date"] != null) contest["date"] = body["date"];
  if (body["status"] != null) contest["status"] = body["status"];
  _logger.info("Updated contest: $id");
  return Response(200, body: jsonEncode({"contest": contest}));
}

Future<Response> deleteContest(Request request, String id) async {
  final removed = contests.remove(id);
  if (removed == null) {
    return Response(404, body: jsonEncode({"error": "not_found"}));
  }
  _logger.info("Deleted contest: $id");
  return Response(204);
}

void main() async {
  Logger.root.level = Level.INFO;

  final router = Router();

  router.get("/health", getHealth);
  router.get("/api/contests", getContests);
  router.get("/api/contests/<id>", (request, id) => getContest(request, id));
  router.post("/api/contests", createContest);
  router.put("/api/contests/<id>", (request, id) => updateContest(request, id));
  router.delete("/api/contests/<id>", (request, id) => deleteContest(request, id));


  final pipeline = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsHeaders())
    .addHandler(router.call);

  final server = await serve(pipeline.call, "0.0.0.0", 8080);
  _logger.info("API server running at http://${server.address.address}:${server.port}");
}