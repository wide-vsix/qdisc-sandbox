.PHONY: up
up: 
	sudo clab deploy

.PHONY: down
down: 
	sudo clab destroy

.PHONY: enable-simple-tc
enable-simple-tc: disable-tc
	tc qdisc add dev eth3 root tbf rate 100mbit burst 10mbit latency 50ms

.PHONY: enable-fair-tc
enable-fair-c: disable-tc
	tc qdisc add dev eth3 root handle 1: htb default 10
	tc class add dev eth3 parent 1: classid 1:1 htb rate 100mbit burst 15k
	tc class add dev eth3 parent 1:1 classid 1:10 htb rate 100mbit ceil 100mbit burst 15k
	tc qdisc add dev eth3 parent 1:10 handle 10: sfq perturb 10

.PHONY: enable-unfair-tc
enable-unfair-tc: disable-tc
	# TBF qdiscの追加（100Mbpsの帯域制限を設定）
	tc qdisc add dev eth3 root handle 1: tbf rate 100mbit burst 10mbit latency 50ms
	# FIFO qdiscの追加
	tc qdisc add dev eth3 parent 1: handle 2: pfifo limit 100

.PHONY: disable-tc
disable-tc:
	tc qdisc del dev eth3 root || true

.PHONY: restart
restart: down up

.PHONY: bridge
bridge: 
	sudo ip link add AP type bridge
	# for make ufw ignoring bridge traffic.
	if ! grep -q "net/bridge/bridge-nf-call-ip6tables = 0" /etc/ufw/sysctl.conf; then echo "net/bridge/bridge-nf-call-ip6tables = 0" | sudo tee -a /etc/ufw/sysctl.conf; fi
	if ! grep -q "net/bridge/bridge-nf-call-iptables = 0" /etc/ufw/sysctl.conf; then echo "net/bridge/bridge-nf-call-iptables = 0" | sudo tee -a /etc/ufw/sysctl.conf; fi
	if ! grep -q "net/bridge/bridge-nf-call-arptables = 0" /etc/ufw/sysctl.conf; then echo "net/bridge/bridge-nf-call-arptables = 0" | sudo tee -a /etc/ufw/sysctl.conf; fi
	sudo ufw reload
	sudo ip link set up dev AP

.PHONY: clean-bridge
clean-bridge: 
	sudo ip link delete AP
