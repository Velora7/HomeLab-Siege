HomeLab-Siege

A hands-on network security lab where I attacked, analyzed, and defended a virtual target using real Linux tools.


Built with: KVM/QEMU | Kali Linux | Ubuntu Server | Nmap | tcpdump | tshark | iptables | Bash


What This Project Is

I built this lab to understand how attackers think and how defenders stop them. No simulations, no shortcuts — just real tools on real virtual machines.

I set up two VMs on my Linux Mint machine using KVM. One runs Kali Linux as the attacker. The other runs Ubuntu Server as the target. I scanned the target with Nmap, captured every packet with tcpdump, analyzed the traffic with tshark, and blocked the attacker using iptables.

This project gave me practical experience in network reconnaissance, packet analysis, and Linux firewall management. Everything is documented here — logs, captures, scripts, and what I learned.


VM Specs:

VM          OS                  RAM     CPU     Disk    IP Address
Attacker    Kali Linux 2026.2   4GB     2 vCPU  25GB    192.168.122.197
Target      Ubuntu Server 22.04 2GB     1 vCPU  15GB    192.168.122.68

Network: libvirt NAT on 192.168.122.0/24, gateway 192.168.122.1, DHCP managed by libvirt.


The Attack

I started by scanning the target to see what was open.

First scan:
nmap -sS 192.168.122.68

Found two open ports:
- Port 23: Telnet
- Port 80: Apache HTTP

Then I dug deeper to find out what versions were running and what OS the target was using.

nmap -sV -O -T4 192.168.122.68

Results:
- Telnet: Linux telnetd
- Apache: 2.4.52 (Ubuntu)
- OS: Linux (Ubuntu, kernel 4.x or 5.x)

Next, I ran vulnerability scripts to check for known issues.

nmap --script vuln 192.168.122.68

Key findings:
- Telnet uses plaintext communication. No encryption.
- Apache is serving the default page.
- The target is running common, older services.

Finally, I ran a full aggressive scan combining everything.

nmap -sS -sV -O -T4 --script vuln 192.168.122.68 -oX nmap_full.xml

All attack data was saved and later analyzed.


Capturing the Traffic

While the attack was running, I captured all network traffic on the target machine using tcpdump.

sudo tcpdump -i enp1s0 -w capture.pcap

Total packets captured: 2799
Packets dropped: 0

Then I analyzed the capture using tshark.

To see all packets:
tshark -r capture.pcap | head -20

To filter traffic from the attacker:
tshark -r capture.pcap -Y "ip.src==192.168.122.197"

To find SYN packets:
tshark -r capture.pcap -Y "tcp.flags.syn==1"

To see Telnet traffic:
tshark -r capture.pcap -Y "tcp.port==23"

What I saw:
- SYN packets sent to every port from 0 to 65535.
- SYN-ACK responses on ports 23 and 80.
- RST responses on closed ports.
- Plaintext Telnet traffic.
- Nmap probing Apache for version info.

The packet capture gave me full visibility into the attack. Without it, I would have been blind.


The Defense

Once I confirmed the attack was real, I blocked the attacker using iptables on the target machine.

sudo iptables -I INPUT 1 -s 192.168.122.197 -j DROP

This rule:
- Goes to the top of the firewall chain.
- Drops all traffic from the attacker’s IP.
- Works silently — the attacker sees nothing.

I automated this with a script (scripts/defense.sh) that also:
- Rate limits web traffic.
- Drops invalid packets.
- Blocks common scan patterns.

To verify the defense worked, I tried pinging the target from Kali.

ping 192.168.122.68

Result: 100% packet loss. All traffic was dropped. The attacker was fully blocked.

I also checked iptables counters:
pkts bytes target     source               destination
   12  1008 DROP      192.168.122.197      0.0.0.0/0

The count kept going up. The block was working.


Results Summary

Attack:
- Found two open services (Telnet and Apache)
- Identified OS and versions
- Ran vulnerability checks
- Completed full scan in under 20 seconds

Defense:
- Blocked attacker IP
- Applied rate limiting and scan detection
- Verified with ping test
- 100% packet loss confirmed

Packet Capture:
- Captured 2799 packets
- Analyzed with tshark
- Full visibility into attacker behavior


Project Structure

HomeLab-Siege/
├── README.md
├── scripts/defense.sh
├── logs/
│   ├── nmap_scan.txt
│   ├── capture.pcap
│   └── iptables_rules.txt
├── docs/
│   ├── topology.txt
│   ├── scan_results.csv
│   └── analysis.txt
├── reports/
│   ├── nmap_full.xml
│   └── nmap_epic.xml
└── images/
    ├── nmap_scan.png
    ├── ping_blocked.png
    └── tcpdump_capture.png


What I Learned

Some things I’ll take away from this project:

Visibility is everything. Without tcpdump, I wouldn’t have seen the attack happening. Packet captures turn an abstract scan into something you can actually see and analyze.

Firewall rules need to be placed correctly. Inserting the block at the top of the chain made sure it took effect before any allow rules. Small detail, big impact.

Nmap is a powerful tool. In less than a minute, I had a full picture of the target — open ports, services, OS, and potential vulnerabilities.

Telnet is still out there. It’s insecure, uses plaintext, and should be replaced with SSH. But it’s a great service to practice on.

Automation makes defense repeatable. Writing a bash script meant I could apply the same firewall rules instantly across different sessions.

Documentation matters. Writing down what I did helped me organize my thoughts and created a record I can reference later.


