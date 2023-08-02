#!/bin/bash

# Vérifie si un argument (nom de fichier de sortie) est fourni
if [ $# -ne 1 ]; then
  echo "Usage: $0 <fichier_sortie>"
  exit 1
fi

# Nom du fichier de sortie pour enregistrer les résultats
fichier_sortie=$1

# Crée une fonction pour afficher les variables d'environnement
afficher_variables_environnement() {
  if [ -n "$1" ]; then
    while IFS='=' read -r key value; do
      echo "    $key : $value"
    done <<< "$1"
  else
    echo "    Aucune variable d'environnement."
  fi
}

# Crée le fichier de sortie ou le vide s'il existe déjà
> "$fichier_sortie"

# Enregistre les informations dans le fichier de sortie
{
  echo "Système d'exploitation :"
  echo "  Famille : $(uname -s)"
  echo "  Distribution : $(cat /etc/redhat-release 2>/dev/null || echo 'N/A')"
  echo "  Version : $(cat /etc/redhat-release 2>/dev/null || echo 'N/A')"
  echo "  Release : $(uname -r)"
  echo ""
  echo "Architecture : $(uname -m)"
  echo ""
  echo "Kernel :"
  echo "  Nom : $(uname -o)"
  echo "  Version : $(uname -r)"
  echo ""

  # Détection de la virtualisation
  virt_type="Non virtualisé"
  if dmidecode | grep -iq 'Manufacturer: VMware'; then
    virt_type="VMware"
  elif dmidecode | grep -iq 'Manufacturer: Microsoft Corporation' && dmidecode | grep -iq 'Product Name: Virtual Machine'; then
    virt_type="Hyper-V"
  elif dmidecode | grep -iq 'Manufacturer: QEMU'; then
    virt_type="QEMU/KVM"
  elif dmidecode | grep -iq 'Manufacturer: Xen'; then
    virt_type="Xen"
  elif dmidecode | grep -iq 'Manufacturer: Parallels'; then
    virt_type="Parallels"
  elif dmidecode | grep -iq 'Manufacturer: Oracle Corporation' && dmidecode | grep -iq 'Product Name: VirtualBox'; then
    virt_type="VirtualBox"
  elif dmesg | grep -iq 'hypervisor\|vmware\|qemu\|kvm\|xen\|parallels\|virtualbox'; then
    virt_type="Virtualisé (autre)"
  fi
  echo "Virtualisation : $virt_type"

  echo ""
  echo "Nom de domaine complet (FQDN) : $(hostname --fqdn 2>/dev/null || echo 'N/A')"
  echo "Domaine : $(dnsdomainname 2>/dev/null || echo 'N/A')"
  echo ""
  echo "Variables d'environnement globales :"
  afficher_variables_environnement "$(env)"
  echo ""
  echo "Date et heure actuelles :"
  echo "  Date : $(date '+%Y-%m-%d')"
  echo "  Heure : $(date '+%H:%M:%S')"
  echo ""
  echo "DNS :"
  echo "Nameservers :"
  for nameserver in $(grep nameserver /etc/resolv.conf | awk '{print $2}'); do
    echo "  - $nameserver"
  done
  echo ""
  echo "Search Domains :"
  for domain in $(grep search /etc/resolv.conf | awk '{print $2}'); do
    echo "  - $domain"
  done

  echo ""
  echo "Utilisateurs, leurs variables d'environnement et leurs tâches cron :"
  echo "-----------------------------------------------"
  echo ""
  users=$(cut -d: -f1 /etc/passwd)
  for user in $users; do
    if [ "$user" != "root" ]; then
      echo "Utilisateur : $user"
      echo "  Variables d'environnement :"
      afficher_variables_environnement "$(sudo -u $user printenv)"
      echo ""

      # Tâches cron de l'utilisateur
      cron_output=$(sudo -u "$user" crontab -l 2>/dev/null)
      if [ -n "$cron_output" ]; then
        echo "  Tâches cron :"
        echo "$cron_output"
        echo ""
      else
        echo "  Tâches cron : Aucune tâche cron définie pour cet utilisateur."
        echo ""
      fi
    fi
  done
} >> "$fichier_sortie"

echo "Le script a terminé avec succès. Les résultats ont été enregistrés dans $fichier_sortie."
