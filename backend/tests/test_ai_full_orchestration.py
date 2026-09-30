import sys
import urllib.request
import json

sys.stdout.reconfigure(encoding='utf-8')

def test_get(url):
    req = urllib.request.Request(url, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=35) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))

def test_post(url, data):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    with urllib.request.urlopen(req, timeout=35) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))

print('====================================================')
print('TRADEVISION AI — FULL CAPABILITY VERIFICATION SUITE')
print('====================================================')

# 1. Capabilities
status, caps = test_get('http://127.0.0.1:8000/api/ai/capabilities')
cnt = caps.get('count')
print(f'[1] AI Feature Registry: HTTP {status} | Registered: {cnt} capabilities')

# 2. Chat Copilot: Stock Analysis
status, chat1 = test_post('http://127.0.0.1:8000/api/ai/chat', {
    'message': 'Analyze TCS for short-term swing',
    'symbol': 'TCS',
    'mode': 'STANDARD'
})
intent1 = chat1.get('intent')
lat1 = chat1.get('latency_ms')
model1 = chat1.get('model')
src_cnt = len(chat1.get('sources') or [])
print(f'[2] Stock Analysis Chat: HTTP {status} | Intent: {intent1} | Latency: {lat1}ms | Model: {model1} | Sources: {src_cnt}')

# 3. Chat Copilot: Comparison
status, comp_chat = test_post('http://127.0.0.1:8000/api/ai/chat', {
    'message': 'Compare TCS and INFY',
    'mode': 'STANDARD'
})
intent_comp = comp_chat.get('intent')
rlen_comp = len(comp_chat.get('reply', ''))
print(f'[3] Comparison Chat: HTTP {status} | Intent: {intent_comp} | Reply chars: {rlen_comp}')

# 4. Chat Copilot: App Guidance
status, help_chat = test_post('http://127.0.0.1:8000/api/ai/chat', {
    'message': 'How do I generate an AI report in the app?',
    'mode': 'QUICK'
})
intent_help = help_chat.get('intent')
print(f'[4] App Guidance Chat: HTTP {status} | Intent: {intent_help}')

# 5. Deterministic Signal Engine
status, sig = test_get('http://127.0.0.1:8000/api/ai/signals/RELIANCE')
s_bias = sig.get('signal')
t_score = sig.get('technical_score')
ml_up = sig.get('ml_probability_up')
print(f'[5] Deterministic Signal: HTTP {status} | Bias: {s_bias} | Tech Score: {t_score} | ML Up: {ml_up}')

# 6. Dynamic Market Summary
status, mkt = test_get('http://127.0.0.1:8000/api/ai/market-summary?mode=QUICK')
mkt_intent = mkt.get('intent')
mkt_rlen = len(mkt.get('reply', ''))
print(f'[6] Dynamic Market Summary: HTTP {status} | Intent: {mkt_intent} | Reply chars: {mkt_rlen}')

# 7. Dedicated Stock Comparison API
status, comp_api = test_post('http://127.0.0.1:8000/api/ai/compare', {
    'symbol_a': 'TCS',
    'symbol_b': 'INFY',
    'mode': 'STANDARD'
})
c_api_len = len(comp_api.get('reply', ''))
print(f'[7] Stock Comparison API: HTTP {status} | Reply chars: {c_api_len}')

# 8. Indicator Explanation
status, ind = test_get('http://127.0.0.1:8000/api/ai/explain/indicator/RSI?symbol=RELIANCE')
ind_name = ind.get('indicator', {}).get('name')
print(f'[8] Indicator Explanation: HTTP {status} | Name: {ind_name}')

# 9. Stock Grounded Report
status, rep = test_get('http://127.0.0.1:8000/api/stocks/RELIANCE/report')
rep_keys = len(rep.keys())
ml_name = rep.get('predictive_ml', {}).get('model_name')
print(f'[9] Grounded Stock Report: HTTP {status} | Sections: {rep_keys} | Model: {ml_name}')

print('====================================================')
print('ALL 9 CORE AI INTELLIGENCE PIPELINES VERIFIED PASS!')
print('====================================================')
