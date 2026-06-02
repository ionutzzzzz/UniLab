#!/usr/bin/env python3
"""
Simple Python server for UniLab backend.
Listens on localhost and provides JSON-RPC interface for code execution.
"""

import sys
import json
import asyncio
import socket
import pathlib
import argparse
import time
import uuid
import os

# Set web mode to enable base64 plot data returning
os.environ['UNILAB_WEB_MODE'] = '1'
os.environ['QT_QPA_PLATFORM'] = 'offscreen'

# Add parent directory to path so we can import backend
backend_dir = pathlib.Path(__file__).parent
sys.path.insert(0, str(backend_dir))
sys.path.insert(0, str(backend_dir.parent))

from core.models import SessionInfo
from core.engines.transpiler import TranspilerEngine

class UniLabServer:
    def __init__(self, host='127.0.0.1', port=9999):
        self.host = host
        self.port = port
        self.sessions = {}
        self.session_writers = {}

    async def handle_connection(self, reader, writer):
        """Handle a client connection."""
        try:
            while True:
                # Read JSON-RPC request
                line = await reader.readline()
                if not line:
                    break

                try:
                    request = json.loads(line.decode().strip())
                    response = await self.process_request(request, writer)
                except json.JSONDecodeError as e:
                    response = {"error": f"Invalid JSON: {e}"}
                except Exception as e:
                    response = {"error": str(e)}

                # Send JSON response
                writer.write(json.dumps(response).encode() + b'\n')
                await writer.drain()
        finally:
            # Clean up writer from all sessions
            for sid in list(self.session_writers.keys()):
                if writer in self.session_writers[sid]:
                    self.session_writers[sid].remove(writer)
            
            writer.close()
            await writer.wait_closed()

    async def process_request(self, request, writer):
        """Process a JSON-RPC request."""
        method = request.get('method')
        params = request.get('params', {})
        session_id = params.get('session_id')

        # Register writer for session if it exists
        if session_id and session_id in self.sessions:
            if session_id not in self.session_writers:
                self.session_writers[session_id] = []
            if writer not in self.session_writers[session_id]:
                self.session_writers[session_id].append(writer)

        if method == 'create_session':
            return self.create_session(params.get('username', 'default_user'), writer)
        elif method == 'execute':
            return await self.execute(params.get('session_id'), params.get('code'))
        elif method == 'get_workspace':
            return self.get_workspace(params.get('session_id'))
        elif method == 'get_autocomplete':
            return self.get_autocomplete(params.get('session_id'), params.get('text', ''))
        elif method == 'list_files':
            return self.list_files(params.get('session_id'))
        elif method == 'create_file':
            return self.create_file(params.get('session_id'), params.get('filename'), params.get('content', ''))
        elif method == 'get_info':
            return self.get_info()
        elif method == 'list_sessions':
            return self.list_sessions()
        else:
            return {'error': f'Unknown method: {method}'}

    def get_info(self):
        """Get server information."""
        return {
            'version': '0.1.0',
            'name': 'UniLab Python Server',
            'status': 'active',
            'capabilities': [
                'execution',
                'workspace',
                'files',
                'autocomplete',
                'plotting'
            ]
        }

    def list_sessions(self):
        """List active sessions."""
        return {
            'sessions': list(self.sessions.keys()),
            'count': len(self.sessions)
        }

    def create_session(self, username, writer=None):
        """Create a new session."""
        try:
            session_id = str(uuid.uuid4())
            workspace = pathlib.Path('/tmp') / f'unilab_{session_id}'
            workspace.mkdir(exist_ok=True)

            session_info = SessionInfo(
                session_id=session_id,
                username=username,
                engine='transpiler',
                started_at=time.time(),
                workspace_path=workspace
            )

            engine = TranspilerEngine(session_info)
            
            # Set up real-time workspace update callback
            async def on_workspace_changed(variables):
                try:
                    # Safely serialize variables to JSON
                    json_str = json.dumps(variables)
                    event = {
                        "type": "event",
                        "event": "workspace_updated",
                        "session_id": session_id,
                        "variables": json.loads(json_str)  # Re-parse to ensure clean JSON
                    }
                    data = (json.dumps(event) + '\n').encode()

                    writers = self.session_writers.get(session_id, [])
                    for w in list(writers):
                        try:
                            w.write(data)
                            await w.drain()
                        except Exception as e:
                            print(f"Error broadcasting to writer: {e}")
                            if w in writers:
                                writers.remove(w)
                except Exception as e:
                    print(f"Error in on_workspace_changed: {e}")

            engine.on_workspace_changed = on_workspace_changed
            self.sessions[session_id] = engine

            if writer:
                if session_id not in self.session_writers:
                    self.session_writers[session_id] = []
                self.session_writers[session_id].append(writer)

            return {
                'session_id': session_id,
                'success': True
            }
        except Exception as e:
            return {'error': str(e), 'success': False}

    async def execute(self, session_id, code):
        """Execute code in a session."""
        try:
            if session_id not in self.sessions:
                return {'error': 'Session not found', 'success': False}

            engine = self.sessions[session_id]
            result = await engine.run_code(code)

            # Convert dataclass to dict
            from dataclasses import asdict
            result_dict = asdict(result)
            result_dict['success'] = result.success
            return result_dict
        except Exception as e:
            return {'error': str(e), 'success': False, 'stdout': '', 'stderr': '', 'duration_s': 0.0}

    def get_workspace(self, session_id):
        """Get workspace variables."""
        try:
            if session_id not in self.sessions:
                return {'variables': {}}

            engine = self.sessions[session_id]
            variables = engine._get_variables()
            return {'variables': variables}
        except Exception as e:
            print(f'Error getting workspace: {e}', file=sys.stderr)
            return {'variables': {}}

    def get_autocomplete(self, session_id, text):
        """Get autocomplete suggestions."""
        try:
            if session_id not in self.sessions:
                return {'suggestions': []}

            engine = self.sessions[session_id]
            suggestions = engine.complete(text, text)
            return {'suggestions': suggestions}
        except Exception as e:
            return {'suggestions': []}

    def list_files(self, session_id):
        """List files in workspace."""
        try:
            if session_id not in self.sessions:
                return {'files': []}

            engine = self.sessions[session_id]
            files = []
            if engine.workspace_path.exists():
                for entry in engine.workspace_path.iterdir():
                    files.append({
                        'name': entry.name,
                        'path': str(entry),
                        'size': entry.stat().st_size if entry.is_file() else 0,
                        'is_directory': entry.is_dir()
                    })
            return {'files': files}
        except Exception as e:
            return {'files': []}

    def create_file(self, session_id, filename, content):
        """Create a file in the workspace."""
        try:
            if session_id not in self.sessions:
                return {'error': 'Session not found', 'success': False}

            engine = self.sessions[session_id]
            file_path = engine.workspace_path / filename
            file_path.write_text(content)
            return {'success': True, 'path': str(file_path)}
        except Exception as e:
            return {'error': str(e), 'success': False}

    async def start(self):
        """Start the server."""
        server = await asyncio.start_server(
            self.handle_connection,
            self.host,
            self.port
        )

        addr = server.sockets[0].getsockname()
        print(f'UniLab server listening on {addr[0]}:{addr[1]}')

        async with server:
            await server.serve_forever()

async def main():
    parser = argparse.ArgumentParser(description='UniLab Python Backend Server')
    parser.add_argument('--host', default='127.0.0.1', help='Server host')
    parser.add_argument('--port', type=int, default=9999, help='Server port')
    args = parser.parse_args()

    server = UniLabServer(host=args.host, port=args.port)
    await server.start()

if __name__ == '__main__':
    asyncio.run(main())
