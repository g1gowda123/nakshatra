#!/usr/bin/env python3
"""Add a branded offline loading screen + mobile meta to the exported web page."""
import os, re, sys, hashlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HTML = os.path.join(ROOT, "nakshatra", "build", "web", "index.html")
PCK = os.path.join(ROOT, "nakshatra", "build", "web", "index.pck")

with open(HTML, encoding="utf-8") as f:
    html = f.read()

# Cache-bust the pack: Godot's service worker will happily serve a stale pck
# otherwise, and a shipped update would never reach returning players.
if os.path.exists(PCK):
    stamp = hashlib.sha256(open(PCK, "rb").read()).hexdigest()[:10]
    html = html.replace('"executable":"index"', f'"executable":"index","mainPack":"index.pck?v={stamp}"')

if "nk-loader" in html:
    with open(HTML, "w", encoding="utf-8") as f:
        f.write(html)
    print("already polished (pack stamp refreshed)")
    sys.exit(0)

meta = '''		<meta name="theme-color" content="#060910">
		<meta name="mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
'''
html = html.replace('<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">',
                    '<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">\n' + meta)

css = '''		<style id="nk-loader">
			#status {
				background:
					radial-gradient(1100px 620px at 72% 18%, #16233f 0%, rgba(22,35,63,0) 62%),
					radial-gradient(900px 520px at 18% 82%, #111c33 0%, rgba(17,28,51,0) 58%),
					#060910;
				font-family: Georgia, "Times New Roman", serif;
				color: #f2e8d5;
				z-index: 2;
			}
			#status .nk-wrap {
				text-align: center;
				padding: 24px;
			}
			#status .nk-kicker {
				font-family: "Noto Sans", Arial, sans-serif;
				letter-spacing: .34em;
				font-size: 10px;
				text-transform: uppercase;
				color: #d9b36c;
			}
			#status .nk-title {
				font-size: clamp(46px, 9vw, 94px);
				letter-spacing: .07em;
				color: #d9b36c;
				margin: 10px 0 0;
				font-weight: 600;
				line-height: 1.05;
			}
			#status .nk-sub {
				font-family: "Noto Sans", Arial, sans-serif;
				letter-spacing: .32em;
				font-size: 11px;
				color: rgba(244, 236, 221, .82);
				margin-top: 10px;
			}
			#status .nk-kn {
				color: rgba(217, 179, 108, .9);
				font-size: 18px;
				margin-top: 12px;
			}
			#status progress {
				-webkit-appearance: none;
				appearance: none;
				border: none;
				width: min(360px, 72vw);
				height: 4px;
				margin-top: 28px;
				background: rgba(242, 232, 213, .12);
				border-radius: 0;
				overflow: hidden;
			}
			#status progress::-webkit-progress-bar { background: rgba(242, 232, 213, .12); }
			#status progress::-webkit-progress-value {
				background: #d9b36c;
				border-radius: 0;
			}
			#status progress::-moz-progress-bar {
				background: #d9b36c;
				border-radius: 0;
			}
			#status .nk-hint {
				font-family: "Noto Sans", Arial, sans-serif;
				font-size: 11px;
				letter-spacing: .08em;
				color: rgba(150, 164, 187, .9);
				margin-top: 14px;
			}
			#status .nk-foot {
				position: absolute;
				bottom: 24px;
				left: 0; right: 0;
				text-align: center;
				font-family: "Noto Sans", Arial, sans-serif;
				font-size: 10px;
				letter-spacing: .12em;
				color: rgba(150, 164, 187, .55);
			}
			#status-notice { font-family: "Noto Sans", Arial, sans-serif; }
		</style>
'''
html = html.replace("\t</head>", css + "\t</head>")

status = '''		<div id="status">
			<div class="nk-wrap">
				<div class="nk-kicker">A sky lab for curious minds</div>
				<div class="nk-title">NAKSHATRA</div>
				<div class="nk-sub">THE SKY WEAVERS</div>
				<div class="nk-kn">ನಕ್ಷತ್ರ</div>
				<progress id="status-progress"></progress>
				<div class="nk-hint" id="nk-hint">Preparing the night sky…</div>
				<div id="status-notice"></div>
			</div>
			<div class="nk-foot">A free-choice space lab · Classes 6–9 · works offline</div>
		</div>'''
html = re.sub(r'\t\t<div id="status">.*?\n\t\t</div>\n', status + "\n", html, count=1, flags=re.S)

with open(HTML, "w", encoding="utf-8") as f:
    f.write(html)
print("polished", HTML)
