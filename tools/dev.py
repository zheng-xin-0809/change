"""Run Flutter tools inside fitness_app_dev without global PATH/config changes."""
from pathlib import Path
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PREFIX = Path(sys.prefix)
if PREFIX.name != 'fitness_app_dev':
    raise SystemExit('Use: conda run --no-capture-output -n fitness_app_dev python tools/dev.py <command>')
TOOLS = PREFIX / 'tools'
SDK = TOOLS / 'android-sdk'
env = os.environ.copy()
env.update({
    'JAVA_HOME': str(PREFIX/'Library'/'lib'/'jvm'),
    'ANDROID_HOME': str(SDK),
    'ANDROID_SDK_ROOT': str(SDK),
    'PUB_CACHE': str(TOOLS/'pub-cache'),
    'GRADLE_USER_HOME': str(TOOLS/'gradle-cache'),
    'PATH': os.pathsep.join([str(TOOLS/'flutter'/'bin'), str(SDK/'platform-tools'), str(PREFIX/'Library'/'lib'/'jvm'/'bin'), env['PATH']]),
})
flutter = str(TOOLS/'flutter'/'bin'/'flutter.bat')
commands = {
    'doctor': ['doctor', '-v'],
    'devices': ['devices'],
    'create': ['create', '--platforms=android', '--org=com.local.fitnotes', '--project-name=fit_notes', '.'],
    'deps': ['pub', 'get'],
    'l10n': ['gen-l10n'],
    'format': ['format'],
    'analyze': ['analyze'],
    'test': ['test'],
    'build': ['build', 'apk', '--debug'],
    'run': ['run'],
    'integration': ['test', 'integration_test/app_test.dart'],
}
name = sys.argv[1] if len(sys.argv) > 1 else 'doctor'
if name == 'check':
    for args in [['gen-l10n'], ['analyze'], ['test']]:
        subprocess.run([flutter, *args], cwd=ROOT, env=env, check=True)
elif name == 'format':
    subprocess.run([str(TOOLS/'flutter'/'bin'/'dart.bat'), 'format', 'lib', 'test', 'integration_test'], cwd=ROOT, env=env, check=True)
elif name == 'install':
    apk = ROOT/'build'/'app'/'outputs'/'flutter-apk'/'app-debug.apk'
    if not apk.exists():
        raise SystemExit('Build the APK first: python tools/dev.py build')
    adb = str(SDK/'platform-tools'/'adb.exe')
    subprocess.run([adb, *sys.argv[2:], 'install', '-r', str(apk)], cwd=ROOT, env=env, check=True)
elif name in commands:
    subprocess.run([flutter, *commands[name], *sys.argv[2:]], cwd=ROOT, env=env, check=True)
else:
    raise SystemExit('Commands: '+', '.join(commands)+', check, install')
