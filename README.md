# Стенд для домашнего занятия "Загрузка системы"

Домашнее задание
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

##### Запишем заранее подготовленные файлы
Строка в меню grub для загрузки через init=/bin/sh:

    box.vm.provision "file", source: "./42-init-sh", destination: "/tmp/42-init-sh"
Строка в меню grub для загрузки через rd.break:

    box.vm.provision "file", source: "./43-init-break", destination: "/tmp/43-init-break"
Файлы для встраивания модуля в initramfs

    box.vm.provision "file", source: "./module-setup.sh", destination: "/tmp/module-setup.sh"
    box.vm.provision "file", source: "./test.sh", destination: "/tmp/test.sh"
Файл для выполнения задания со *

    box.vm.provision "file", source: "./stage-2.sh", destination: "/home/vagrant/"


В данном стенде используется GUI VirtualBox
### Задание 1: Попасть в систему без пароля несколькими способами
##### Запишем несколько пунктов меню в загрузчик GRUB для входа в систему без пароля и увеличим timeout меню
    cp {/tmp/42-init-sh,/tmp/43-init-break} /etc/grub.d/ # копируем файлы из папки tmp
    chmod +x {/etc/grub.d/42-init-sh,/etc/grub.d/43-init-break}
    sed -i 's/GRUB_TIMEOUT=1/GRUB_TIMEOUT=15/' /etc/default/grub # увеличим таймаут до 15 сек.
##### Перезапишем конфиг GRUB
    grub2-mkconfig -o /boot/grub2/grub.cfg

При загрузке пункта CentOS Linux rescue init=/bin/sh" необходимо перемонтировать систему в режим записи командой

    mount -o remount,rw /

При загрузке пункта CentOS Linux rescue rd.break необходимо перемонтировать систему в режим записи командой

    mount -o remount,rw /sysroot
затем сменить корень командой

    chroot /sysroot


После внесения изменений перемонтируйте систему в режим чтения командой

    mount -o remount,ro /
и перезагрузитесь

    /sbin/reboot -f

### Задание 2: Установить систему с LVM, после чего переименовать VG
##### Смотрим текущее состояние системы командой vgs
      vgs
##### Переименуем VolGroup00 в OtusRoot
      vgrename VolGroup00 OtusRoot
##### Сделаем правки в /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg, /etc/grub.d/*
      sed -i 's/VolGroup00/OtusRoot/g' {/etc/fstab,/etc/default/grub,/boot/grub2/grub.cfg,/etc/grub.d/*}
##### Перезапишем initramfs
      dracut -f /boot/initramfs-$(uname -r).img $(uname -r)

Есть какой то глюк с VirtualBox (6.0.2) после команды reboot система останавливается с черным экраном. При перезапуске с хоста всё работает и в дальнейшем система работает нормально.

https://otus-linux.slack.com/archives/CPDUZP0N7/p1574173521294900

### Задание 3: Добавить модуль в initrd
##### Создаем папку с модулем и запишем туда файлы
      mkdir /usr/lib/dracut/modules.d/01test
      cp {/tmp/module-setup.sh,/tmp/test.sh} /usr/lib/dracut/modules.d/01test # копируем файлы из папки tmp
      chmod +x /usr/lib/dracut/modules.d/01test/*
##### Перезапишем initramfs и подправим настройки grub
      dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
      sed -i 's/ rhgb quiet//' {/etc/default/grub,/boot/grub2/grub.cfg}


### Задание со *. Сконфигурировать систему без отдельного раздела с /boot, а только с LVM

Для выполнения задания создан скрипт stage-2.sh
Его необходимо запустить вручную после перезагрузки системы.

#### Скрипт stage-2.sh
##### Перепишем каталог boot во временный каталог
    sudo mkdir /tmp/boot
    sudo cp -p -r /boot/* /tmp/boot
##### Отмонтируем boot и создадим раздел lvm
    sudo umount /boot
    sudo pvcreate -y /dev/sda2 --bootloaderareasize 1m
    sudo vgcreate vg_boot /dev/sda2
    sudo lvcreate -n lv_boot -l +100%FREE /dev/vg_boot
##### Форматируем раздел и переписываем boot обратно
    sudo mkfs.xfs -q /dev/vg_boot/lv_boot
    sudo mount /dev/vg_boot/lv_boot /boot
    sudo cp -p -r /tmp/boot/* /boot
##### Поменяем необходимые настройки в grub и перезапишем fstab
    echo 'GRUB_PRELOAD_MODULES="lvm"' | sudo tee -a /etc/default/grub
    sudo sed -i 's/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"dolvm /' /etc/default/grub
    sudo sed -i s%UUID=570897ca-e759-4c81-90cf-389da6eee4cc%/dev/mapper/vg_boot-lv_boot% /etc/fstab

##### Не забываем про пункты меню rescue
    sudo sed -i s%570897ca-e759-4c81-90cf-389da6eee4cc%/$(sudo blkid -s UUID -o value /dev/mapper/vg_boot-lv_boot)%g {/etc/grub.d/42-init-sh,/etc/grub.d/43-init-break}
##### Перезапишем загрузчик
    sudo grub2-install --recheck /dev/sda # без этой команды не работало (удаляет cd /boot/grub2/device.map)
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg


Вывод команды lsblk:

    NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                     8:0    0   40G  0 disk
    ├─sda1                  8:1    0    1M  0 part
    ├─sda2                  8:2    0    1G  0 part
    │ └─vg_boot-lv_boot   253:2    0 1020M  0 lvm  /boot
    └─sda3                  8:3    0   39G  0 part
      ├─OtusRoot-LogVol00 253:0    0 37.5G  0 lvm  /
      └─OtusRoot-LogVol01 253:1    0  1.5G  0 lvm  [SWAP] lsblk:

Вывод команды vgs:

    VG       #PV #LV #SN Attr   VSize    VFree
    OtusRoot   1   2   0 wz--n-  <38.97g    0
    vg_boot    1   1   0 wz--n- 1020.00m    0
Все задания выполнены.

Спасибо за проверку!
