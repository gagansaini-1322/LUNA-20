#!/usr/bin/env python3
"""Luna Hub - System Monitor Backend (Flask)"""

import os
import subprocess
import json
from flask import Flask, jsonify, request

app = Flask(__name__)

def get_cpu_temp():
    try:
        with open('/sys/class/thermal/thermal_zone0/temp') as f:
            return round(int(f.read().strip()) / 1000, 1)
    except:
        return 0.0

def get_fan_rpm():
    try:
        result = subprocess.run(['sensors'], capture_output=True, text=True, timeout=2)
        for line in result.stdout.split('\n'):
            if 'fan' in line.lower() and 'rpm' in line.lower():
                parts = line.split()
                for p in parts:
                    if p.isdigit():
                        return int(p)
        return 0
    except:
        return 0

def get_gpu_info():
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=gpu_name,utilization.gpu,memory.used,memory.total',
                                '--format=csv,noheader,nounits'],
                               capture_output=True, text=True, timeout=2)
        if result.returncode == 0:
            parts = result.stdout.strip().split(', ')
            return {
                'name': parts[0],
                'load': int(parts[1]),
                'vram_used': int(parts[2]),
                'vram_total': int(parts[3]),
                'driver': 'nvidia'
            }
    except:
        pass

    try:
        for card_dir in sorted(os.listdir('/sys/class/drm/')):
            if card_dir.startswith('card') and card_dir[-1].isdigit():
                busy_path = f'/sys/class/drm/{card_dir}/device/gpu_busy_percent'
                vram_path = f'/sys/class/drm/{card_dir}/device/mem_info_vram_used'
                vram_total_path = f'/sys/class/drm/{card_dir}/device/mem_info_vram_total'
                if os.path.exists(busy_path):
                    with open(busy_path) as f:
                        load = int(f.read().strip())
                    vram_used = 0
                    vram_total = 0
                    if os.path.exists(vram_path):
                        with open(vram_path) as f:
                            vram_used = int(f.read().strip()) // (1024 * 1024)
                    if os.path.exists(vram_total_path):
                        with open(vram_total_path) as f:
                            vram_total = int(f.read().strip()) // (1024 * 1024)
                    name_path = f'/sys/class/drm/{card_dir}/device/product_name'
                    name = 'AMD GPU'
                    if os.path.exists(name_path):
                        with open(name_path) as f:
                            name = f.read().strip()
                    return {
                        'name': name,
                        'load': load,
                        'vram_used': vram_used,
                        'vram_total': vram_total,
                        'driver': 'amdgpu'
                    }
    except:
        pass

    return {'name': 'Integrated GPU', 'load': 0, 'vram_used': 0, 'vram_total': 0, 'driver': 'unknown'}

def get_battery_info():
    try:
        bat_path = '/sys/class/power_supply/BAT0'
        if not os.path.exists(bat_path):
            return {'level': -1, 'plugged': False}

        with open(f'{bat_path}/capacity') as f:
            level = int(f.read().strip())
        with open(f'{bat_path}/status') as f:
            plugged = f.read().strip() == 'Charging'
        return {'level': level, 'plugged': plugged}
    except:
        return {'level': -1, 'plugged': False}

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/api/stats')
def stats():
    import psutil

    cpu_percent = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory()
    temp = get_cpu_temp()
    fan = get_fan_rpm()
    gpu = get_gpu_info()
    battery = get_battery_info()

    return jsonify({
        'cpu_percent': cpu_percent,
        'ram_used': round(mem.used / (1024**3), 1),
        'ram_total': round(mem.total / (1024**3), 1),
        'ram_percent': mem.percent,
        'cpu_temp': temp,
        'fan_rpm': fan,
        'gpu': gpu,
        'battery': battery
    })

@app.route('/api/perf-mode')
def get_perf_mode():
    try:
        result = subprocess.run(['powerprofilesctl', 'get'], capture_output=True, text=True, timeout=2)
        return jsonify({'mode': result.stdout.strip()})
    except:
        return jsonify({'mode': 'balanced'})

@app.route('/api/perf-mode/<mode>', methods=['POST'])
def set_perf_mode(mode):
    try:
        subprocess.run(['powerprofilesctl', 'set', mode], timeout=2)
        return jsonify({'success': True, 'mode': mode})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5151, debug=False)
