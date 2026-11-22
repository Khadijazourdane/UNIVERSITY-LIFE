import json
from http.server import BaseHTTPRequestHandler, HTTPServer


ROUTES = {
    "/student/grades": [
        {"module": "Bases de données", "score": 15},
        {"module": "Développement mobile", "score": 16},
        {"module": "Réseaux informatiques", "score": 12.5},
    ],
    "/student/absences": [
        {
            "module": "Bases de données",
            "date": "12 novembre 2026",
            "isJustified": True,
        },
        {
            "module": "Réseaux informatiques",
            "date": "5 novembre 2026",
            "isJustified": False,
        },
    ],
    "/student/timetable": [
        {
            "course": "Bases de données",
            "day": "Lundi",
            "startTime": "10 h 30",
            "endTime": "12 h 00",
            "room": "Salle B12",
        },
        {
            "course": "Développement mobile",
            "day": "Lundi",
            "startTime": "14 h 00",
            "endTime": "15 h 30",
            "room": "Salle A04",
        },
        {
            "course": "Réseaux informatiques",
            "day": "Mardi",
            "startTime": "09 h 00",
            "endTime": "10 h 30",
            "room": "Salle C03",
        },
        {
            "course": "Algorithmique",
            "day": "Jeudi",
            "startTime": "11 h 00",
            "endTime": "12 h 30",
            "room": "Salle B08",
        },
    ],
}


class StudentApi(BaseHTTPRequestHandler):
    def do_GET(self):
        data = ROUTES.get(self.path)

        if data is None:
            status = 404
            data = {"error": "URL introuvable"}
        else:
            status = 200

        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))


if __name__ == "__main__":
    print("API étudiante disponible sur http://127.0.0.1:3000")
    HTTPServer(("127.0.0.1", 3000), StudentApi).serve_forever()
