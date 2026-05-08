import os
import psycopg2
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

# ── DB connection from environment variables (never hardcode!) ──────────────
def get_db():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )

# ── Create table if it doesn't exist ────────────────────────────────────────
def init_db():
    conn = get_db()
    conn.cursor().execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id    SERIAL PRIMARY KEY,
            title TEXT NOT NULL,
            body  TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()

# ── HTML frontend (unchanged from v1) ───────────────────────────────────────
HTML = """
<!DOCTYPE html>
<html>
<head>
  <title>Notes App v2</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
    input, textarea { width: 100%; margin: 6px 0; padding: 8px; box-sizing: border-box; }
    button { padding: 8px 16px; cursor: pointer; }
    .note { border: 1px solid #ddd; padding: 12px; margin: 8px 0; border-radius: 4px; }
    .delete { float: right; color: red; border: none; background: none; font-size: 16px; cursor: pointer; }
  </style>
</head>
<body>
  <h2>📝 Notes App v2 — with Postgres</h2>

  <input id="title" placeholder="Title" />
  <textarea id="body" placeholder="Write your note..." rows="3"></textarea>
  <button onclick="addNote()">Add Note</button>

  <hr>
  <div id="notes"></div>

  <script>
    async function loadNotes() {
      const res = await fetch('/notes');
      const data = await res.json();
      const container = document.getElementById('notes');
      container.innerHTML = '';
      data.forEach(note => {
        container.innerHTML += `
          <div class="note">
            <button class="delete" onclick="deleteNote(${note.id})">🗑</button>
            <strong>${note.title}</strong>
            <p>${note.body}</p>
          </div>`;
      });
    }

    async function addNote() {
      const title = document.getElementById('title').value;
      const body  = document.getElementById('body').value;
      await fetch('/notes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, body })
      });
      document.getElementById('title').value = '';
      document.getElementById('body').value  = '';
      loadNotes();
    }

    async function deleteNote(id) {
      await fetch(`/notes/${id}`, { method: 'DELETE' });
      loadNotes();
    }

    loadNotes();
  </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML)

@app.route('/notes', methods=['GET'])
def get_notes():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, title, body FROM notes ORDER BY id DESC")
    rows = [{'id': r[0], 'title': r[1], 'body': r[2]} for r in cur.fetchall()]
    conn.close()
    return jsonify(rows)

@app.route('/notes', methods=['POST'])
def add_note():
    data = request.json
    conn = get_db()
    conn.cursor().execute(
        "INSERT INTO notes (title, body) VALUES (%s, %s)",
        (data['title'], data['body'])
    )
    conn.commit()
    conn.close()
    return jsonify({'status': 'created'}), 201

@app.route('/notes/<int:note_id>', methods=['DELETE'])
def delete_note(note_id):
    conn = get_db()
    conn.cursor().execute("DELETE FROM notes WHERE id = %s", (note_id,))
    conn.commit()
    conn.close()
    return jsonify({'status': 'deleted'})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)