#!/usr/bin/env bash
gh label create 'priority: high'   -c '#b60205' -d 'Alta prioridade' || true
gh label create 'priority: medium' -c '#d93f0b' -d 'Média prioridade' || true
gh label create 'priority: low'    -c '#fbca04' -d 'Baixa prioridade' || true
gh label create 'area: mobile'     -c '#0e8a16' -d 'Flutter app' || true
gh label create 'area: data'       -c '#1d76db' -d 'DB/Export/GeoJSON' || true
gh label create 'area: map'        -c '#0052cc' -d 'Mapa/POIs' || true
gh label create 'area: devops'     -c '#5319e7' -d 'CI/CD/Build' || true
gh label create 'type: feature'    -c '#0e8a16' -d 'New functionality' || true
gh label create 'type: bug'        -c '#d73a4a' -d 'Bug fix or issue' || true
gh label create 'type: chore'      -c '#cfd3d7' -d 'Chore or maintenance task' || true
gh label create 'good first issue' -c '#7057ff' -d 'Issue de entrada' || true
