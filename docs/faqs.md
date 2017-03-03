# FAQs / Hints

## Why is the CPU usage so high on the salt mater?

Salt masters take a long time to boot up, just how it is. They should startup in about 10-20 seconds, then the CPU will die down.

## My minion stopped responding to the master after destroyed/re-created it

Delete the salt key and re-restart he minion's salt daemon.

1. On the master: ```salt-key -d minionId ```
2. On the minion:  ```service salt-minion restart```
