#!/bin/bash
# Copyright 2023 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

set -euo pipefail

# Extract all OVF Properties
VEBA_PAUSE=$(/root/setup/getOvfProperty.py "guestinfo.pause")
VEBA_DEBUG=$(/root/setup/getOvfProperty.py "guestinfo.debug")
TANZU_SOURCES_DEBUG=$(/root/setup/getOvfProperty.py "guestinfo.tanzu_sources_debug")
HOSTNAME=$(/root/setup/getOvfProperty.py "guestinfo.hostname" | tr '[:upper:]' '[:lower:]')
IP_ADDRESS=$(/root/setup/getOvfProperty.py "guestinfo.ipaddress")
NETMASK=$(/root/setup/getOvfProperty.py "guestinfo.netmask" | awk -F ' ' '{print $1}')
GATEWAY=$(/root/setup/getOvfProperty.py "guestinfo.gateway")
DNS_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.dns")
DNS_DOMAIN=$(/root/setup/getOvfProperty.py "guestinfo.domain")
NTP_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.ntp")
HTTP_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.http_proxy")
HTTPS_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.https_proxy")
PROXY_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.proxy_username")
PROXY_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.proxy_password")
NO_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.no_proxy")
ROOT_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.root_password")
ENABLE_SSH=$(/root/setup/getOvfProperty.py "guestinfo.enable_ssh" | tr '[:upper:]' '[:lower:]')
ENDPOINT_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.endpoint_username")
ENDPOINT_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.endpoint_password")
VCENTER_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_server")
VCENTER_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_username")
VCENTER_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_password")
VCENTER_USERNAME_FOR_VEBA_UI=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_veba_ui_username")
VCENTER_PASSWORD_FOR_VEBA_UI=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_veba_ui_password")
VCENTER_DISABLE_TLS=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_disable_tls_verification")
VCENTER_CHECKPOINTING_AGE=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_checkpoint_age")
VCENTER_CHECKPOINTING_PERIOD=$(/root/setup/getOvfProperty.py "guestinfo.vcenter_checkpoint_period")
HORIZON_ENABLED=$(/root/setup/getOvfProperty.py "guestinfo.horizon")
HORIZON_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.horizon_server")
HORIZON_DOMAIN=$(/root/setup/getOvfProperty.py "guestinfo.horizon_domain")
HORIZON_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.horizon_username")
HORIZON_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.horizon_password")
HORIZON_DISABLE_TLS=$(/root/setup/getOvfProperty.py "guestinfo.horizon_disable_tls_verification")
WEBHOOK_ENABLED=$(/root/setup/getOvfProperty.py "guestinfo.webhook")
WEBHOOK_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.webhook_username")
WEBHOOK_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.webhook_password")
CUSTOM_VEBA_TLS_PRIVATE_KEY=$(/root/setup/getOvfProperty.py "guestinfo.custom_tls_private_key")
CUSTOM_VEBA_TLS_CA_CERT=$(/root/setup/getOvfProperty.py "guestinfo.custom_tls_ca_cert")
POD_NETWORK_CIDR=$(/root/setup/getOvfProperty.py "guestinfo.pod_network_cidr")
SYSLOG_SERVER_HOSTNAME=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_hostname")
SYSLOG_SERVER_PORT=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_port")
SYSLOG_SERVER_PROTOCOL=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_protocol")
SYSLOG_SERVER_FORMAT=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_format")
KUBECTL_WAIT="10m"
LOCAL_STORAGE_DISK="/dev/sdb"
LOCAL_STOARGE_VOLUME_PATH="/data"
export KUBECONFIG="/root/.kube/config"

if [ -e /root/ran_customization ]; then
    exit
else
	VEBA_LOG_FILE=/var/log/bootstrap.log
	if [ ${VEBA_DEBUG} == "True" ]; then
		VEBA_LOG_FILE=/var/log/bootstrap-debug.log
		set -x
		exec 2>> ${VEBA_LOG_FILE}
		echo
        echo "### WARNING -- DEBUG LOG CONTAINS ALL EXECUTED COMMANDS WHICH INCLUDES CREDENTIALS -- WARNING ###"
        echo "### WARNING --             PLEASE REMOVE CREDENTIALS BEFORE SHARING LOG            -- WARNING ###"
        echo
	fi

	# Customize the pause if provided or else default to 15s
	if [ -z "${VEBA_PAUSE}" ]; then
		VEBA_PAUSE="15"
	fi

	# Customize the POD CIDR Network if provided or else default to 10.10.0.0/16
	if [ -z "${POD_NETWORK_CIDR}" ]; then
		POD_NETWORK_CIDR="10.16.0.0/16"
	fi

	# Slicing of escaped variables needed to properly handle the double quotation issue
	ESCAPED_VCENTER_SERVER=$(eval echo -n '${VCENTER_SERVER}' | jq -Rs .)
	ESCAPED_VCENTER_USERNAME=$(eval echo -n '${VCENTER_USERNAME}' | jq -Rs .)
	ESCAPED_VCENTER_PASSWORD=$(eval echo -n '${VCENTER_PASSWORD}' | jq -Rs .)
	ESCAPED_ROOT_PASSWORD=$(eval echo -n '${ROOT_PASSWORD}' | jq -Rs .)
	ESCAPED_ENDPOINT_USERNAME=$(eval echo -n '${ENDPOINT_USERNAME}' | jq -Rs .)
	ESCAPED_ENDPOINT_PASSWORD=$(eval echo -n '${ENDPOINT_PASSWORD}' | jq -Rs .)

	ESCAPED_VCENTER_USERNAME_FOR_VEBA_UI=$(eval echo -n '${VCENTER_USERNAME_FOR_VEBA_UI}' | jq -Rs .)
	ESCAPED_VCENTER_PASSWORD_FOR_VEBA_UI=$(eval echo -n '${VCENTER_PASSWORD_FOR_VEBA_UI}' | jq -Rs .)

	ESCAPED_HORIZON_SERVER=$(eval echo -n '${HORIZON_SERVER}' | jq -Rs .)
	ESCAPED_HORIZON_USERNAME=$(eval echo -n '${HORIZON_USERNAME}' | jq -Rs .)
	ESCAPED_HORIZON_PASSWORD=$(eval echo -n '${HORIZON_PASSWORD}' | jq -Rs .)

	ESCAPED_WEBHOOK_USERNAME=$(eval echo -n '${WEBHOOK_USERNAME}' | jq -Rs .)
	ESCAPED_WEBHOOK_PASSWORD=$(eval echo -n '${WEBHOOK_PASSWORD}' | jq -Rs .)

	ESCAPED_PROXY_PASSWORD=$(eval echo -n '${PROXY_PASSWORD}' | jq -Rs .)

	cat > /root/config/veba-config.json <<EOF
{
	"VEBA_PAUSE": "${VEBA_PAUSE}",
	"VEBA_DEBUG": "${VEBA_DEBUG}",
	"TANZU_SOURCES_DEBUG": "${TANZU_SOURCES_DEBUG}",
	"HOSTNAME": "${HOSTNAME}",
	"IP_ADDRESS": "${IP_ADDRESS}",
	"NETMASK": "${NETMASK}",
	"GATEWAY": "${GATEWAY}",
	"DNS_SERVER": "${DNS_SERVER}",
	"DNS_DOMAIN": "${DNS_DOMAIN}",
	"NTP_SERVER": "${NTP_SERVER}",
	"HTTP_PROXY": "${HTTP_PROXY}",
	"HTTPS_PROXY": "${HTTPS_PROXY}",
	"PROXY_USERNAME": "${PROXY_USERNAME}",
	"PROXY_PASSWORD": ${ESCAPED_PROXY_PASSWORD},
	"NO_PROXY": "${NO_PROXY}",
	"ESCAPED_ROOT_PASSWORD": ${ESCAPED_ROOT_PASSWORD},
	"ENABLE_SSH": "${ENABLE_SSH}",
	"ESCAPED_ENDPOINT_USERNAME": ${ESCAPED_ENDPOINT_USERNAME},
	"ESCAPED_ENDPOINT_PASSWORD": ${ESCAPED_ENDPOINT_PASSWORD},
	"ESCAPED_VCENTER_SERVER": ${ESCAPED_VCENTER_SERVER},
	"ESCAPED_VCENTER_USERNAME": ${ESCAPED_VCENTER_USERNAME},
	"ESCAPED_VCENTER_PASSWORD": ${ESCAPED_VCENTER_PASSWORD},
	"ESCAPED_VCENTER_USERNAME_FOR_VEBA_UI": ${ESCAPED_VCENTER_USERNAME_FOR_VEBA_UI},
	"ESCAPED_VCENTER_PASSWORD_FOR_VEBA_UI": ${ESCAPED_VCENTER_PASSWORD_FOR_VEBA_UI},
	"VCENTER_DISABLE_TLS": "${VCENTER_DISABLE_TLS}",
	"VCENTER_CHECKPOINTING_AGE": ${VCENTER_CHECKPOINTING_AGE},
	"VCENTER_CHECKPOINTING_PERIOD": ${VCENTER_CHECKPOINTING_PERIOD},
	"HORIZON_ENABLED": "${HORIZON_ENABLED}",
	"ESCAPED_HORIZON_SERVER": ${ESCAPED_HORIZON_SERVER},
	"HORIZON_DOMAIN": "${HORIZON_DOMAIN}",
	"ESCAPED_HORIZON_USERNAME": ${ESCAPED_HORIZON_USERNAME},
	"ESCAPED_HORIZON_PASSWORD": ${ESCAPED_HORIZON_PASSWORD},
	"HORIZON_DISABLE_TLS": "${HORIZON_DISABLE_TLS}",
	"WEBHOOK_ENABLED": "${WEBHOOK_ENABLED}",
	"ESCAPED_WEBHOOK_USERNAME": ${ESCAPED_WEBHOOK_USERNAME},
	"ESCAPED_WEBHOOK_PASSWORD": ${ESCAPED_WEBHOOK_PASSWORD},
	"CUSTOM_VEBA_TLS_PRIVATE_KEY": "${CUSTOM_VEBA_TLS_PRIVATE_KEY}",
	"CUSTOM_VEBA_TLS_CA_CERT": "${CUSTOM_VEBA_TLS_CA_CERT}",
	"POD_NETWORK_CIDR": "${POD_NETWORK_CIDR}",
	"SYSLOG_SERVER_HOSTNAME": "${SYSLOG_SERVER_HOSTNAME}",
	"SYSLOG_SERVER_PORT": "${SYSLOG_SERVER_PORT}",
	"SYSLOG_SERVER_PROTOCOL": "${SYSLOG_SERVER_PROTOCOL}",
	"SYSLOG_SERVER_FORMAT": "${SYSLOG_SERVER_FORMAT}"
}
EOF

	echo -e "\e[92mStarting Customization ..." > /dev/console

	echo -e "\e[92mStarting OS Configuration ..." > /dev/console
	. /root/setup/setup-01-os.sh

	echo -e "\e[92mStarting Network Proxy Configuration ..." > /dev/console
	. /root/setup/setup-02-proxy.sh

	echo -e "\e[92mStarting Network Configuration ..." > /dev/console
	. /root/setup/setup-03-network.sh

	echo -e "\e[92mStarting Kubernetes Configuration ..." > /dev/console
	. /root/setup/setup-04-kubernetes.sh

	echo -e "\e[92mStarting Knative Configuration ..." > /dev/console
	. /root/setup/setup-05-knative.sh

	echo -e "\e[92mStarting vSphere Sources Configuration ..." > /dev/console
	. /root/setup/setup-06-vsphere-sources.sh

	if [ ${HORIZON_ENABLED} == "True" ]; then
		echo -e "\e[92mStarting Horizon Sources Configuration ..." > /dev/console
		. /root/setup/setup-06-horizon-sources.sh
	fi

	if [ ${WEBHOOK_ENABLED} == "True" ]; then
		echo -e "\e[92mStarting VMware Event Provider Webhook Configuration ..." > /dev/console
		. /root/setup/setup-07-event-router-webhook.sh
	fi

	echo -e "\e[92mStarting TinyWWW Configuration ..." > /dev/console
	. /root/setup/setup-08-tinywww.sh

	echo -e "\e[92mStarting Ingress Router Configuration ..." > /dev/console
	. /root/setup/setup-09-ingress.sh

	if [[ ! -z ${VCENTER_USERNAME_FOR_VEBA_UI} ]] && [[ ! -z ${VCENTER_PASSWORD_FOR_VEBA_UI} ]]; then
		echo -e "\e[92mStarting Knative UI Configuration ..." > /dev/console
		. /root/setup/setup-010-veba-ui.sh
	fi

	if [ -n "${SYSLOG_SERVER_HOSTNAME}" ]; then
		echo -e "\e[92mStarting FluentBit Configuration ..." > /dev/console
		. /root/setup/setup-011-fluentbit.sh
	fi

	echo -e "\e[92mStarting cAdvisor Configuration ..." > /dev/console
	. /root/setup/setup-012-cadvisor.sh

	echo -e "\e[92mStarting VEBA Endpoint File Configuration ..." > /dev/console
	. /root/setup/setup-098-dcui-endpoints.sh

	echo -e "\e[92mStarting OS Banner Configuration ..."> /dev/console
	. /root/setup/setup-099-banner.sh &

	echo -e "\e[92mCustomization Completed ..." > /dev/console

	# Clear guestinfo.ovfEnv
	if [ ${VEBA_DEBUG} == "False" ]; then
		vmtoolsd --cmd "info-set guestinfo.ovfEnv NULL"
	fi

	# Ensure we don't run customization again
	touch /root/ran_customization
fi