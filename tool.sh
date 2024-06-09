#!/bin/bash

# tool.conf dosyasının yolu
tool_conf_path="./tool.conf"

# Çıktı dosyasının yolu
output_file="./output.txt"

# Cihazın varlığını kontrol et
function check_device {
    local devices_output
    devices_output=$(./adb devices)

    if echo "$devices_output" | grep -q -E 'device$'; then
        return 0 # Cihaz bulundu
    else
        return 1 # Cihaz bulunamadı
    fi
}

# Geri yükleme işlemi
function restore {
    if [ ! -f "$tool_conf_path" ]; then
        echo "tool.conf dosyası bulunamadı. Geri yükleme yapılamıyor."
        exit 1
    fi

    # packages dizisini al
    packages=$(sed -n '/^packages=/,/)/p' "$tool_conf_path" | sed 's/packages=//; s/["()]//g')

    # Her bir paketi kaldır ve yükle
    apps=($packages)
    for app in "${apps[@]}"; do
        echo "Paket geri yükleniyor: $app"
        ./adb shell cmd package install-existing "$app"
        if [ $? -eq 0 ]; then
            echo "$app geri yüklendi."
        else
            echo "$app geri yüklenemedi."
        fi

        # 2 saniye bekle
        sleep 2
    done
}

# Komut satırı argümanlarını kontrol et
if [ "$1" == "restore" ]; then
    if ! check_device; then
        echo "Cihaz bulunamadı. Lütfen bir cihaz bağladığınızdan emin olun."
        exit 1
    fi

    restore
    exit 0
fi

# Cihazın var olup olmadığını kontrol et
if ! check_device; then
    echo "Cihaz bulunamadı. Lütfen bir cihaz bağladığınızdan emin olun."
    exit 1
fi

# bloatware değerini kontrol et
bloatware=$(grep -oP 'bloatware=\K\d' "$tool_conf_path")

if [ "$bloatware" -eq 1 ]; then
    echo "bloatware=1 değeri tool.conf dosyasında bulunmaktadır. Paketler kaldırılacak."

    # packages dizisini al
    packages=$(sed -n '/^packages=/,/)/p' "$tool_conf_path" | sed 's/packages=//; s/["()]//g')

    # Eğer output.txt dosyası varsa sil
    if [ -f "$output_file" ]; then
        rm "$output_file"
    fi

    # Her bir paketi kaldır ve dosyaya kaydet
    apps=($packages)
    for app in "${apps[@]}"; do
        echo "Kaldırılan paket: $app"
        ./adb shell pm uninstall --user 0 "$app"
        if [ $? -eq 0 ]; then
            echo "$app" >> "$output_file"
        fi
    done

    echo "Paketler başarıyla kaldırıldı. Geri yüklemek için './tool.sh restore' komutunu kullanın."

else
    echo "bloatware=1 değeri tool.conf dosyasında bulunmamaktadır. Paketler kaldırılmayacak."
fi
