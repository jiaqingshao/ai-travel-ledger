// PATCH a GitHub release with proper UTF-8 encoded body
const fs = require('fs');
const https = require('https');

const token = process.env.GH_TOKEN;
if (!token) {
  console.error('GH_TOKEN env not set');
  process.exit(1);
}

const json = fs.readFileSync('_patch.json', 'utf8');
const releaseId = process.env.RELEASE_ID || '353844756';

const options = {
  hostname: 'api.github.com',
  port: 443,
  path: '/repos/jiaqingshao/ai-travel-ledger/releases/' + releaseId,
  method: 'PATCH',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(json, 'utf8'),
    'User-Agent': 'ai-travel-ledger-release-fixup',
  },
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        const r = JSON.parse(body);
        console.log('Updated name:', r.name);
        console.log('URL:', r.html_url);
        console.log('Body length:', r.body ? r.body.length : 0, 'chars');
        console.log('First 80 body chars:', (r.body || '').substring(0, 80));
      } catch (e) {
        console.log('Body:', body.substring(0, 200));
      }
    } else {
      console.log('Error body:', body.substring(0, 500));
    }
  });
});
req.on('error', (e) => console.error('Req error:', e.message));
req.write(json);
req.end();
