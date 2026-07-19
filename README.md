HomeLab Siege

This is a red team / blue team exercise I built on my own machine to practice network security, packet analysis, and Linux defense. I used KVM virtual machines to isolate the environment.

------------------------------------------------------------

Lab Setup

- Attacker machine: Kali Linux with IP 192.168.122.197
- Target machine: Ubuntu Server 22.04 with IP 192.168.122.68
- Hypervisor: KVM / QEMU on Linux Mint
- Network: Default libvirt NAT network

Both VMs are running on the same host. The target has no firewall enabled at the start. This lets me simulate a real unprotected server.

------------------------------------------------------------

Attack Phase

I started by running Nmap from the Kali machine to scan the target. I used a standard SYN scan to check for open ports. I also added service detection to see what was running on each port.

Nmap command:
nmap -sS -sV 192.168.122.68

Results showed two open ports:
- Port 23 / TCP - Telnet service
- Port 80 / TCP - Apache HTTP server

Telnet is a known insecure protocol. It sends credentials in plain text. This made the target vulnerable to basic attacks.

I also checked the Apache default page to confirm the service was running properly.

------------------------------------------------------------

Packet Capture Phase

While the scan was running I started tcpdump on the Ubuntu target. I saved everything to a pcap file.

Command:
sudo tcpdump -i enp1s0 -w capture.pcap

After the scan ended I stopped tcpdump and opened the file with tshark. I wanted to see what the Nmap scan actually looked like on the wire.

I filtered for SYN packets coming from the Kali IP. I could clearly see the port by port probe. Each port got a SYN packet and the target responded with SYN-ACK for open ports or RST for closed ones.

I also looked at the Telnet traffic later to confirm it was working.

------------------------------------------------------------

Defense Phase

Once I confirmed the attack was visible in the packet capture I moved to defense. I used iptables to block the attacker.

I inserted a rule at the top of the INPUT chain to drop all traffic from Kali.

Command:
sudo iptables -I INPUT 1 -s 192.168.122.197 -j DROP

To test I tried pinging the target from Kali. The ping hung and eventually timed out with 100 percent packet loss.

I checked the iptables counters and saw the dropped packets increasing. This confirmed the rule was working.

------------------------------------------------------------

What I Learned

Packet capture gives you full visibility into what is hitting your machine. Without it I would only know that a scan happened but not how or when.

Firewall rules are effective but need to be placed correctly. Inserting at the top of the chain made sure the block happened before any allow rules.

This lab gave me hands on experience with tools I have only read about before. It also showed me how attackers think when they are looking for open doors.

------------------------------------------------------------

Tools Used

- Kali Linux
- Ubuntu Server
- Nmap
- tcpdump
- tshark / Wireshark
- iptables
- KVM / libvirt
- virt-install
- virt-viewer

------------------------------------------------------------

Next Steps

I plan to add more targets and services to this lab. I also want to try using Suricata for intrusion detection and log analysis. Another idea is to simulate a web application attack using DVWA or a similar deliberately vulnerable app.

This project will keep growing as I learn more.

