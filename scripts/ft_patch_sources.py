#!/usr/bin/env python3
"""fast-track kit: the upstream source patches the guide applies by hand (Days 12, 14, 27, 28, 54) plus the
Instana vendor-tracer removal. Idempotent: running it twice changes nothing the second time.
Run from the roboshop-app repo root (scripts/ft-prepare-app.sh calls it)."""
import json, re, pathlib, sys

P = pathlib.Path
changed = []

def edit(path, fn):
    p = P(path)
    if not p.exists():
        sys.exit(f"missing {path} - import upstream first (scripts/ft-prepare-app.sh step 1)")
    old = p.read_text()
    new = fn(old)
    if new != old:
        p.write_text(new); changed.append(path); print(f"   patched {path}")
    else:
        print(f"   ok      {path}")

# --- Instana removal (Node): keep a tiny stub so the existing middleware (span.annotate) still works ---
STUB = ("const instana = { currentSpan: () => ({ annotate: () => {} }) };"
        "  // fast-track kit: Instana collector removed (OpenTelemetry in Phase 8)\n")
INIT = re.compile(r"const instana = require\('@instana/collector'\);\n// init tracing\n"
                  r"// MUST be done before loading anything else!\ninstana\(\{\n\s*tracing: \{\n\s*enabled: true\n\s*\}\n\}\);\n")
for svc in ['catalogue', 'user', 'cart']:
    edit(f'{svc}/server.js', lambda t: INIT.sub(STUB, t))
    pj = P(f'{svc}/package.json'); d = json.loads(pj.read_text())
    if d.get('dependencies', {}).pop('@instana/collector', None):
        pj.write_text(json.dumps(d, indent=2) + '\n'); changed.append(str(pj)); print(f"   patched {pj} (-@instana/collector)")

# --- Day 12: cart reads CATALOGUE_PORT ---
def cart(t):
    if 'cataloguePort' in t:
        return t
    t = t.replace("var catalogueHost = process.env.CATALOGUE_HOST || 'catalogue'\n",
                  "var catalogueHost = process.env.CATALOGUE_HOST || 'catalogue'\n"
                  "var cataloguePort = process.env.CATALOGUE_PORT || '8080'\n")
    return t.replace("'http://' + catalogueHost + ':8080/product/'",
                     "'http://' + catalogueHost + ':' + cataloguePort + '/product/'")
edit('cart/server.js', cart)

# --- Day 14: payment reads CART_PORT / USER_PORT;  Instana import removed ---
def payment(t):
    t = t.replace('import instana\n', '')
    if 'CART_PORT' in t:
        return t
    t = t.replace("USER = os.getenv('USER_HOST', 'user')\n",
                  "USER = os.getenv('USER_HOST', 'user')\n"
                  "CART_PORT = os.getenv('CART_PORT', '8080')\nUSER_PORT = os.getenv('USER_PORT', '8080')\n")
    t = t.replace("'http://{user}:8080/", "'http://{user}:{uport}/").replace("'http://{cart}:8080/", "'http://{cart}:{cport}/")
    t = t.replace("format(user=USER, id=id)", "format(user=USER, uport=USER_PORT, id=id)")
    return t.replace("format(cart=CART, id=id)", "format(cart=CART, cport=CART_PORT, id=id)")
edit('payment/payment.py', payment)
edit('payment/requirements.txt', lambda t: ''.join(l for l in t.splitlines(True) if l.strip() != 'instana'))

# --- Day 54: payment + dispatch read the RabbitMQ credentials from the environment (default guest) ---
edit('payment/rabbitmq.py', lambda t: t.replace(
    "PlainCredentials('guest', 'guest')",
    "PlainCredentials(os.getenv('AMQP_USER', 'guest'), os.getenv('AMQP_PASS', 'guest'))"))

# --- Day 27: uWSGI must not switch user (the container already runs as non-root) ---
edit('payment/payment.ini', lambda t: re.sub(r'^(uid|gid)\s*=.*\n', '', t, flags=re.M))

def dispatch(t):
    t = t.replace('\t"github.com/instana/go-sensor"\n', '')
    t = re.sub(r'\t// Instana tracing\n\tot\.InitGlobalTracer\(instana\.NewTracerWithOptions\(&instana\.Options\{.*?\}\)\)\n',
               '\t// fast-track kit: Instana tracer removed; ot.GlobalTracer() is the no-op tracer\n', t, flags=re.S)
    if 'AMQP_USER' in t:
        return t
    return t.replace(
        'amqpUri = fmt.Sprintf("amqp://guest:guest@%s:5672/", amqpHost)',
        'amqpUser, ok := os.LookupEnv("AMQP_USER")\n\tif !ok {\n\t\tamqpUser = "guest"\n\t}\n'
        '\tamqpPass, ok := os.LookupEnv("AMQP_PASS")\n\tif !ok {\n\t\tamqpPass = "guest"\n\t}\n'
        '\tamqpUri = fmt.Sprintf("amqp://%s:%s@%s:5672/", amqpUser, amqpPass, amqpHost)')
edit('dispatch/main.go', dispatch)

# --- Day 28: nginx template - no Instana tracer, ratings on :8080, hide version, status only for localhost ---
def web(t):
    t = re.sub(r'^# Instana tracing\nopentracing_load_tracer .*\nopentracing_propagate_context;\n', '', t, flags=re.M)
    t = t.replace('${RATINGS_HOST}:80/', '${RATINGS_HOST}:8080/')
    if 'server_tokens off' not in t:
        t = t.replace('    server_name  localhost;\n', '    server_name  localhost;\n    server_tokens off;\n', 1)
        t = t.replace('        stub_status on;\n', '        stub_status on;\n        allow 127.0.0.1;\n        deny all;\n', 1)
    return t
edit('web/default.conf.template', web)

# --- safety net: nothing may still reference Instana ---
left = [f for f in ['catalogue/server.js', 'user/server.js', 'cart/server.js', 'payment/payment.py', 'dispatch/main.go',
                    'web/default.conf.template'] if re.search(r"require\('@instana|^import instana|instana\.NewTracer|go-sensor|opentracing_load", P(f).read_text(), re.M)]
if left:
    sys.exit(f"Instana references remain in: {left} - upstream changed? patch by hand (see the guide Day 24)")
print(f"   {len(changed)} file(s) changed, no Instana references left")
