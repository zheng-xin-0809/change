from pathlib import Path
import concurrent.futures
import hashlib
import json
import os
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
import subprocess
import sys

ROOT = Path(sys.prefix)
if ROOT.name != 'fitness_app_dev':
    raise SystemExit('Activate fitness_app_dev before running this installer.')
TOOLS = ROOT / 'tools'
CACHE = TOOLS / 'downloads'
CACHE.mkdir(parents=True, exist_ok=True)

def read(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()

releases = json.loads(read('https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'))
release = next(x for x in releases['releases'] if x['version'] == '3.47.6' and x['channel'] == 'stable')
xml = ET.fromstring(read('https://dl.google.com/android/repository/repository2-3.xml'))
package = next(x for x in xml.findall('remotePackage') if x.attrib['path'] == 'cmdline-tools;23.0')
archive = next(x for x in package.findall('archives/archive') if x.findtext('host-os') == 'windows')
complete = archive.find('complete')
android_url = complete.findtext('url')
checksum = complete.find('checksum')
android_hash_type = checksum.attrib.get('type', 'sha1')

def install(label, url, digest, algorithm, target):
    marker = TOOLS/'flutter'/'bin'/'flutter.bat' if label.startswith('Flutter') else TOOLS/'android-sdk'/'cmdline-tools'/'latest'/'bin'/'android.exe'
    if marker.exists():
        print(f'{label}: already installed', flush=True)
        return
    dest = CACHE / url.rsplit('/', 1)[-1]
    if not dest.exists():
        print(f'Downloading {label}: {url}', flush=True)
        with urllib.request.urlopen(url, timeout=90) as response, dest.open('wb') as stream:
            total = int(response.headers.get('Content-Length', 0))
            downloaded = 0
            threshold = 100 * 1024 * 1024
            while chunk := response.read(4 * 1024 * 1024):
                stream.write(chunk)
                downloaded += len(chunk)
                if downloaded >= threshold:
                    print(f'{label}: {downloaded // (1024*1024)} MiB / {total // (1024*1024)} MiB', flush=True)
                    threshold += 100 * 1024 * 1024
    with dest.open('rb') as stream:
        actual = hashlib.file_digest(stream, algorithm).hexdigest()
    if actual != digest:
        raise RuntimeError(f'{label} checksum mismatch. Remove incomplete archive and rerun: {dest}')
    print(f'{label}: verified {algorithm}; extracting', flush=True)
    with zipfile.ZipFile(dest) as z:
        for item in z.infolist():
            resolved = (target / item.filename).resolve()
            if not resolved.is_relative_to(target.resolve()):
                raise RuntimeError('Unsafe archive path')
        z.extractall(target)
    print(f'{label}: installed at {target}', flush=True)

with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    jobs = [
        pool.submit(install, 'Flutter '+release['version'], releases['base_url']+'/'+release['archive'], release['sha256'], 'sha256', TOOLS),
        pool.submit(install, 'Android command-line tools', 'https://dl.google.com/android/repository/'+android_url, checksum.text, android_hash_type, TOOLS/'android-sdk'/'cmdline-tools'/'unpack'),
    ]
    for job in jobs:
        job.result()
source = TOOLS/'android-sdk'/'cmdline-tools'/'unpack'/'cmdline-tools'
target = TOOLS/'android-sdk'/'cmdline-tools'/'latest'
if not target.exists():
    source.rename(target)
(TOOLS/'versions.json').write_text(json.dumps({'flutter': release, 'android_command_line_tools': android_url}, indent=2), encoding='utf-8')
print('SDK downloads complete.', flush=True)

android = str(target/'bin'/'android.exe')
sdk_env = os.environ.copy()
sdk_env['JAVA_HOME'] = str(ROOT/'Library'/'lib'/'jvm')
sdk_env['ANDROID_HOME'] = str(TOOLS/'android-sdk')
sdk_env['PATH'] = os.pathsep.join([str(ROOT/'Library'/'lib'/'jvm'/'bin'), sdk_env['PATH']])
for component in ['platform-tools', 'platforms;android-36', 'platforms;android-35', 'build-tools;36.0.0', 'ndk;28.2.13676358', 'cmake;3.22.1']:
    subprocess.run([android, '--sdk='+str(TOOLS/'android-sdk'), 'sdk', 'install', component], env=sdk_env, check=True)
print('Android components ready.', flush=True)
