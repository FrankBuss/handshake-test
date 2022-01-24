#!/usr/bin/python3

import http.server, ssl

server_address = ('localhost', 4443)
httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
httpd.socket = ssl.wrap_socket(httpd.socket,
                               server_side=True,
                               certfile='../handout/conf/ssl/metaroot.crt',
                               keyfile='../handout/conf/ssl/metaroot.key',
                               ssl_version=ssl.PROTOCOL_TLS)
httpd.serve_forever()

