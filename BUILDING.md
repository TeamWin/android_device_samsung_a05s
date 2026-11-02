# TWRP 12.1 para Galaxy A05s: teste do touch Himax

Esta tree deriva de [TeamWin/android_device_samsung_a05s](https://github.com/TeamWin/android_device_samsung_a05s),
branch `android-12.1`. O kernel, os módulos e os firmwares prebuilts são os do projeto original.
Os créditos aos contribuidores originais permanecem no README e no histórico Git.

O objetivo é testar o carregamento de `hx83112f.ko` no recovery, preservando os drivers
Chipone, Goodix e Ilitek. Uma compilação bem-sucedida não comprova funcionamento do touch.

## Alterações

- `TW_LOAD_VENDOR_MODULES` lista apenas arquivos `.ko`.
- `TW_LOAD_VENDOR_BOOT_MODULES` habilita a busca em `/lib/modules` no ramdisk.
- O serviço existente de touch consulta seus módulos e os módulos de plataforma,
  com os dois `--dirname` suportados pelo modprobe Android da branch 12.1.
- A aspa de fechamento inválida de `FOX_TARGET_DEVICES` em `vendorsetup.sh` foi corrigida.
- O build aplica `.github/patches/preserve-tracking-id-release.patch` ao TWRP.
  Na captura real, o Himax envia tracking ID `-1`, touch-major zero e pressão zero
  no mesmo frame. O parser original sobrescreve o sinal explícito de soltar o dedo
  e não entrega `TOUCH_RELEASE` à interface. O ajuste preserva esse sinal e possui
  teste de regressão sobre a função original de tratamento dos eventos.

O build TeamWin copia `recovery/root/` automaticamente; não há cópia duplicada por
`PRODUCT_COPY_FILES`. A pasta `Patches/` e todos os arquivos binários permanecem intactos.
O workflow impede a execução do hook JDM preexistente usando o lock que esse script
já reconhece, pois `TW_NO_HAPTICS=true` neste produto.

## Compilar no GitHub Actions

O workflow **Build TWRP a05s (Himax)** executa a cada push na branch `main` e também
pode ser iniciado manualmente em **Actions → Run workflow**.

Ele usa o manifest mínimo `twrp-12.1`, verifica as versões dos módulos Himax/Chipone,
testa o tratamento do fim do toque, compila somente `recoveryimage` com o kernel prebuilt e verifica os arquivos de touch
no ramdisk gerado. Não modifica vbmeta nem grava qualquer partição do aparelho.

Ao terminar, baixe o artefato da execução. Em caso de sucesso, ele contém:

- `recovery.img` e `recovery.tar`;
- `SHA256SUMS`;
- `build.log`, logs de sincronização e `build-info.txt`;
- `resolved-manifest.xml`, com os commits dos fontes utilizados.

Em caso de falha, os logs disponíveis são enviados no mesmo artefato. A retenção é de sete dias.

## Validar no recovery

Depois de preservar seu recovery original, gravar a imagem por conta própria e iniciar o TWRP:

```sh
adb shell 'uname -r; lsmod | grep -iE "hx83112f|spi_msm_geni|nopmi_chg"'
adb shell 'dmesg | grep -iE "himax|hxtp|hx83112|firmware|Unknown symbol|version magic|disagrees"'
adb shell 'cat /sys/module/hx83112f/parameters/tpsensor'
adb shell 'readlink /sys/bus/spi/devices/spi0.2/driver'
adb shell 'cat /proc/bus/input/devices'
adb shell getevent -lp
adb shell getevent -lt
```

Toque na tela durante `getevent -lt` e observe eventos de posição do `himax-touchscreen`.
A numeração de `eventN` pode mudar. Se falhar, salve os logs antes de reiniciar:

```sh
adb exec-out dmesg > recovery-dmesg.txt
adb pull /tmp/recovery.log
adb pull /tmp/dmesg_a05s.txt
```

O módulo da tree e o kernel declaram a versão `5.15.167-android13-8-ravindu644-TWRP-dev-ab`.
Não substituir o módulo por um extraído de um stock com versão de kernel diferente.
