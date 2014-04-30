minessh
=======

Control mining servers over SSH

**Overview**

Bash script for controlling mining servers running on BAMT 1.3/1.5/1.6 or SMOS Linux (optionally PIMP).
It may control any number of mining servers. It is preferably to run it against BAMT 1.6 servers as script already included easy function to quickly switch over mining software e.g. cgminer/sgminer/vertminer. 
Also it is possible to add your own custom compiled miner and switch to it within menu. 
Tested on Lubuntu 13.10 and on any Debian based distros should work out of box, also it could run on any Linux distro with small modifications.


**Full list of features:**

-Power of secured SSH connection (use only SSH)

-Fully interactive menu

-Email notification when mining failed

-Unlimited number of mining servers

-Automatically adds non-password authentication

-Custom colors for menus and messages

-Reboot selected miner or all together

-View/Edit pool config for selected miner

-Switch over between 4 included mining software in BAMT 1.6 + 2 custom

-Restart mining process on all servers

-Allows to do quick SSH login to mining servers

-Real-time monitoring for all servers in one window

-Crontab tasks to periodically control and reboot dead/sick/idle mining servers



**Initial setup**


1. Download script to any folder
2. Make script executable chmod +x mine.sh
3. Open minessh_config.txt, define mining servers IP and configure pools
4. Launch script ./mine.sh
5. Set up non-password authentication. Press 7 and procceed to further instructions.
6. All done. You may back to menu and choose desired option.

*(Optional)*

7. If you would like to setup cron job then you need to run script with cron parameter. For example to test mining servers every 20 minutes add line to crontab   */20 * * * * /root/mine.sh cron
8. Enable email notifications, set notify="YES" and enter email details. Then while running cron task script will perform checks and if mining failed you will get email. Also at any time you may send mining logs from all miners to defined email, this option available within main menu.
9. For cron job set video card temperature limit.

**How to add your custom miner. As an example explained how to add YACminer.**

1. Copy from other place or compile yacminer in /opt/miners
2. Change directory to /opt/miners/YACminer and rename yacminer binary to cgminer. Make sure it has executable flag "x" if not do chmod +x cgminer
3. Rename /opt/miners/YACminer to /opt/miners/custom
4. Create yacminer configuration file /etc/bamt/custom.conf (Pools and miner settings)
5. Run bamt.sh and choose "Change mining software.." from the menu then in next submenu choose "custom"
6. That's it. Yacminer now default mining software. Mining process will restart automatically.

Note: In same way you may add custom1 miner, but make sure to keep these names /opt/miners/custom1 and /etc/bamt/custom1.conf


Please let me know if you found any bugs or want to suggest something.

**Screenshots**

Main menu: http://simplest-image-hosting.net/png-0-main-m

Mining servers' status:  http://simplest-image-hosting.net/png-0-status0

Switch over between mining software:  http://simplest-image-hosting.net/png-0-mining-soft

Real-time monitoring:  http://simplest-image-hosting.net/png-0-real-time

E-mail notification: http://simplest-image-hosting.net/jpg-0-email

**Updates:**

30.04.2014 -Configuration options sent to external file

13.04.2014 -Added edit config and restart mining option

11.04.2014 -Added email notifications

08.04.2014 -Separated bamt/pimp scripts 

03.04.2014 -Added PIMP support (see PIMP folder)

28.03.2014 -Added card status direct check via cgminer API

25.03.2014 -Added quick ssh login item to menu



**You may send me some bounty to support my work and further improvement:**

BTC: 1PGgybf5QbCTohCoRgEA4Q5ZSLhpSsg8cn

LTC: Lbw6bd3T3XaMypF1XsuryH3J9zMoY7gLTv

