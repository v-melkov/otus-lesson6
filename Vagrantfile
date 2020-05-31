# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
  :lesson6 => {
        :box_name => "centos/7",
        :box_version => "1804.02",
        :ip_addr => '192.168.11.106',
  },
}

Vagrant.configure("2") do |config|

    config.vm.box_version = "1804.02"
    MACHINES.each do |boxname, boxconfig|
        config.vbguest.no_install = true
        config.vm.define boxname do |box|

            box.vm.box = boxconfig[:box_name]
            box.vm.host_name = boxname.to_s

            #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset

            box.vm.network "private_network", ip: boxconfig[:ip_addr]

            box.vm.provider :virtualbox do |vb|
                    vb.customize ["modifyvm", :id, "--memory", "1024"]
                    vb.gui = true
            end
        box.vm.provision "file", source: "./42-init-sh", destination: "/tmp/42-init-sh"
        box.vm.provision "file", source: "./43-init-break", destination: "/tmp/43-init-break"
        box.vm.provision "file", source: "./module-setup.sh", destination: "/tmp/module-setup.sh"
        box.vm.provision "file", source: "./test.sh", destination: "/tmp/test.sh"
        box.vm.provision "file", source: "./stage-2.sh", destination: "/home/vagrant/"
        box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh
            cp ~vagrant/.ssh/auth* ~root/.ssh
            echo "В данном стенде используется GUI VirtualBox"
            echo "Задание 1: Попасть в систему без пароля несколькими способами"
            echo "Запишем несколько пунктов меню в загрузчик GRUB для входа в систему без пароля и увеличим timeout меню"
            cp {/tmp/42-init-sh,/tmp/43-init-break} /etc/grub.d/ # копируем файлы из папки tmp
          #  chmod +x {/etc/grub.d/42-init-sh,/etc/grub.d/43-init-break}
            sed -i 's/GRUB_TIMEOUT=1/GRUB_TIMEOUT=15/' /etc/default/grub # увеличим таймаут до 15 сек.
            echo "Перезапишем конфиг GRUB"
            grub2-mkconfig -o /boot/grub2/grub.cfg
            echo -e "\nПри загрузке пункта CentOS Linux rescue init=/bin/sh"
            echo "необходимо перемонтировать систему в режим записи командой"
            echo "mount -o remount,rw /"
            echo -e "\nПри загрузке пункта CentOS Linux rescue rd.break"
            echo "необходимо перемонтировать систему в режим записи командой"
            echo "mount -o remount,rw /sysroot"
            echo "затем сменить корень командой"
            echo "chroot /sysroot"
            echo -e "\nПосле внесения изменений перемонтируйте систему в режим чтения командой"
            echo "mount -o remount,ro /"
            echo "и перезагрузитесь командой"
            echo "/sbin/reboot -f"
            #sleep 10
            echo -e "\n\n"
            echo "======================================================="
            echo -e "\n\n"
            echo "Задание 2: Установить систему с LVM, после чего переименовать VG"
            echo "Смотрим состояние системы командой vgs"
            vgs
            echo "Переименуем VolGroup00 в OtusRoot"
            vgrename VolGroup00 OtusRoot
            echo "Делаем правки в /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg, /etc/grub.d/*"
            sed -i 's/VolGroup00/OtusRoot/g' {/etc/fstab,/etc/default/grub,/boot/grub2/grub.cfg,/etc/grub.d/*}
            # echo "Перезапишем initramfs"
            # dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
            echo -e "\nЕсть какой то глюк с VirtualBox - после команды reboot"
            echo "система останавливается с черным экраном. При перезапуске с хоста всё работает"
            echo -e "\n\n"
            echo "======================================================="
            echo -e "\n\n"
            echo "Задание 3: Добавить модуль в initrd"
            echo "Создаем папку с модулем и запишем туда файлы"
            mkdir /usr/lib/dracut/modules.d/01test
            cp {/tmp/module-setup.sh,/tmp/test.sh} /usr/lib/dracut/modules.d/01test # копируем файлы из папки tmp
            # chmod +x /usr/lib/dracut/modules.d/01test/*
            echo "Перезапишем initramfs"
            dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
            sed -i 's/ rhgb quiet//' {/etc/default/grub,/boot/grub2/grub.cfg}

            echo -e "\n\n\n"
            echo "Выполнение заданий без * завершено"
            echo -e "\nДля выполнения задания со звездочкой необходимо ресетнуть систему из VirtualBox (если зависнет)"
            echo "После перезагрузки войдите в систему и запустите скрипт stage-2.sh"
            echo "      vagrant ssh      "
            echo "    ./stage-2.sh       "
            shutdown -r now
          SHELL

        end
    end
  end
