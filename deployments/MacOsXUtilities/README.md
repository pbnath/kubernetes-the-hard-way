# Additional Step for Mac Os X Users

## Configure IP Range for Virtual Box

- add a file `/etc/vbox/networks.conf` or add the following line to it:

```conf
* 192.168.5.0/16
```

see [https://www.virtualbox.org/manual/ch06.html#network_hostonly] for complete documentation.