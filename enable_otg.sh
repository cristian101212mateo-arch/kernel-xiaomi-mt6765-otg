#!/bin/bash
# Script para habilitar OTG en el kernel de angelica (Redmi 9C)
# Uso: ./enable_otg.sh

set -e

KERNEL_DIR="$(pwd)"
DTS_DIR="arch/arm64/boot/dts/mediatek"

echo "🔍 Buscando el nodo USB en el árbol de Device Tree..."

# Buscar todos los archivos que definen nodos USB
USB_FILES=$(grep -rl "ssusb\|usbdrd\|dwc3\|musb\|usb0" $DTS_DIR/ 2>/dev/null || true)

if [ -z "$USB_FILES" ]; then
    echo "❌ No se encontró ningún nodo USB en $DTS_DIR"
    exit 1
fi

echo "📂 Archivos con nodos USB encontrados:"
echo "$USB_FILES"
echo ""

# Buscar el nodo USB principal y ver si ya tiene dr_mode
echo "🔍 Analizando configuración actual..."
for f in $USB_FILES; do
    echo "--- $f ---"
    grep -n -B2 -A2 "dr_mode\|ssusb\|usbdrd\|dwc3" "$f" | head -30
    echo ""
done

# Buscar si algún archivo ya tiene dr_mode = "otg"
if grep -rq 'dr_mode = "otg"' $DTS_DIR/; then
    echo "✅ Ya existe una configuración dr_mode = \"otg\". No se necesita hacer nada."
    exit 0
fi

# Si encontramos dr_mode = "peripheral", cambiarlo a "otg"
if grep -rq 'dr_mode = "peripheral"' $DTS_DIR/; then
    echo "🔧 Cambiando dr_mode de \"peripheral\" a \"otg\"..."
    sed -i 's/dr_mode = "peripheral"/dr_mode = "otg"/g' $DTS_DIR/*.dtsi $DTS_DIR/*.dts 2>/dev/null || true
    echo "✅ Cambio aplicado."
    exit 0
fi

# Si no existe dr_mode, añadirlo al nodo USB principal
echo "🔧 No se encontró dr_mode. Buscando nodo USB para añadirlo..."

# Buscar el nombre del nodo USB principal
USB_NODE=$(grep -rhoE '&(ssusb|usbdrd|dwc3|musb|usb0)' $DTS_DIR/*.dts 2>/dev/null | head -1 | tr -d '&')

if [ -z "$USB_NODE" ]; then
    echo "⚠️  No se pudo identificar el nodo USB automáticamente."
    echo "   Revisa manualmente los archivos listados arriba y añade:"
    echo '   dr_mode = "otg";'
    exit 1
fi

echo "📌 Nodo USB identificado: &$USB_NODE"

# Añadir la configuración al final del archivo angelica.dts
cat >> $DTS_DIR/angelica.dts << EOF

/* OTG enablement - añadido por script */
&$USB_NODE {
    dr_mode = "otg";
    status = "okay";
};
