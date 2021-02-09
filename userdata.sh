#! /bin/bash
# sudo apt-get update
# sudo apt-get install -y apache2
# sudo systemctl start apache2
# sudo systemctl enable apache2
echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html

sudo mv /var/ /var.old
sudo mkdir -p /var/log
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/xvdb
sudo mount /dev/xvdb /var/log
sudo cp -f /etc/fstab /etc/fstab.bak
sudo echo '/dev/xvdb /var/log ext4 defaults,nofail 0 2' >> /etc/fstab
