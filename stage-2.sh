#! /bin/bash

echo -e "\nПерепишем каталог boot во временный каталог"
sudo mkdir /tmp/boot
sudo cp -p -r /boot/* /tmp/boot
echo -e "\nОтмонтируем boot и создадим раздел lvm"
sudo umount /boot
sudo pvcreate -y /dev/sda2 --bootloaderareasize 1m
sudo vgcreate vg_boot /dev/sda2
sudo lvcreate -n lv_boot -l +100%FREE /dev/vg_boot
echo -e "\nФорматируем раздел и переписываем boot обратно"
sudo mkfs.xfs -q /dev/vg_boot/lv_boot
sudo mount /dev/vg_boot/lv_boot /boot
sudo cp -p -r /tmp/boot/* /boot
echo -e "\nПоменяем необходимые настройки в grub и перезапишем fstab"
echo 'GRUB_PRELOAD_MODULES="lvm"' | sudo tee -a /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"dolvm /' /etc/default/grub
sudo sed -i s%UUID=570897ca-e759-4c81-90cf-389da6eee4cc%/dev/mapper/vg_boot-lv_boot% /etc/fstab
sudo sed -i s%570897ca-e759-4c81-90cf-389da6eee4cc%$(sudo blkid -s UUID -o value /dev/mapper/vg_boot-lv_boot)%g {/etc/grub.d/42-init-sh,/etc/grub.d/43-init-break}

sudo grub2-install --recheck /dev/sda
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
# sudo reboot

echo -e "\nЗадание со * выполнено"
echo "Спасибо за проверку!"
