#!/usr/bin/env python3
import sys
from pathlib import Path

PERMISSIONS = [
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_LOCATION',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
]

SERVICE_BLOCK = (
    '        <service\n'
    '            android:name="id.flutter.flutter_background_service.BackgroundService"\n'
    '            android:exported="false"\n'
    '            android:foregroundServiceType="location" />\n'
)

RECEIVER_BLOCK = (
    '        <receiver\n'
    '            android:name="id.flutter.flutter_background_service.BootReceiver"\n'
    '            android:enabled="true"\n'
    '            android:exported="false">\n'
    '            <intent-filter>\n'
    '                <action android:name="android.intent.action.BOOT_COMPLETED" />\n'
    '            </intent-filter>\n'
    '        </receiver>\n'
)


def ensure_permissions(text):
    for perm in PERMISSIONS:
        entry = f'    <uses-permission android:name="{perm}" />\n'
        if entry not in text:
            insert_at = text.find('<application')
            if insert_at == -1:
                return text
            text = text[:insert_at] + entry + text[insert_at:]
    return text


def ensure_service(text):
    app_idx = text.find('<application')
    if app_idx == -1:
        return text
    end_app = text.find('>', app_idx)
    if end_app == -1:
        return text
    insert_pos = end_app + 1
    additions = ''
    if 'id.flutter.flutter_background_service.BackgroundService' not in text:
        additions += SERVICE_BLOCK
    if 'id.flutter.flutter_background_service.BootReceiver' not in text:
        additions += RECEIVER_BLOCK
    if not additions:
        return text
    return text[:insert_pos] + '\n' + additions + text[insert_pos:]


def main():
    if len(sys.argv) < 2:
        raise SystemExit('Usage: patch_android_manifest.py <AndroidManifest.xml>')

    path = Path(sys.argv[1])
    text = path.read_text()
    text = ensure_permissions(text)
    text = ensure_service(text)
    path.write_text(text)


if __name__ == '__main__':
    main()
