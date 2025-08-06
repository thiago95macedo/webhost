#!/bin/bash

# Script para gerar favicons em diferentes formatos
# Requer: ImageMagick (convert)

set -e

DASHBOARD_DIR="/opt/webhost/dashboard"
SVG_FILE="$DASHBOARD_DIR/favicon.svg"

echo "🎨 Gerando favicons para o dashboard..."

# Verificar se o ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick não está instalado. Instalando..."
    sudo apt update
    sudo apt install -y imagemagick
fi

# Verificar se o arquivo SVG existe
if [ ! -f "$SVG_FILE" ]; then
    echo "❌ Arquivo SVG não encontrado: $SVG_FILE"
    exit 1
fi

# Gerar favicon.ico (32x32)
echo "📱 Gerando favicon.ico (32x32)..."
convert "$SVG_FILE" -resize 32x32 "$DASHBOARD_DIR/favicon.ico"

# Gerar favicon.png (32x32) - transparente
echo "🖼️  Gerando favicon.png (32x32) - transparente..."
convert "$SVG_FILE" -background transparent -resize 32x32 "$DASHBOARD_DIR/favicon.png"

# Gerar apple-touch-icon.png (180x180) - transparente
echo "🍎 Gerando apple-touch-icon.png (180x180) - transparente..."
convert "$SVG_FILE" -background transparent -resize 180x180 "$DASHBOARD_DIR/apple-touch-icon.png"

# Gerar favicon-16x16.png - transparente
echo "🔍 Gerando favicon-16x16.png - transparente..."
convert "$SVG_FILE" -background transparent -resize 16x16 "$DASHBOARD_DIR/favicon-16x16.png"

# Gerar favicon-32x32.png - transparente
echo "🔍 Gerando favicon-32x32.png - transparente..."
convert "$SVG_FILE" -background transparent -resize 32x32 "$DASHBOARD_DIR/favicon-32x32.png"

echo "✅ Favicons gerados com sucesso!"
echo "📁 Arquivos criados:"
ls -la "$DASHBOARD_DIR"/favicon* "$DASHBOARD_DIR"/apple-touch-icon.png

echo ""
echo "🎯 Favicons disponíveis:"
echo "  - favicon.svg (SVG - moderno)"
echo "  - favicon.ico (ICO - compatibilidade)"
echo "  - favicon.png (PNG - alternativa)"
echo "  - apple-touch-icon.png (iOS/macOS)"
echo "  - favicon-16x16.png (16x16)"
echo "  - favicon-32x32.png (32x32)" 