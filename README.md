# DojoDrops
Serves static websites pages from a DropBox shared folder url.

This project is built to be used in CoderDojo-like environments, where kids want to experiment with html/css/javascript.
Students can edit their sourcefiles on their local filesystem, DropBox stores it in the cloud, and dojodrops picks it up and serves it to the internet.

Sites can be protected with basic authentication too.

The DropBox api for fetching content tends to be a bit slow, DojoDrops caches the content in memory so it can be served quickly, content will be refreshed when DropBox syncs new content.

To avoid a single user taking down the server, DojoDrops does not serve files over 256KB. It will instead return a 409.

I have plans to add a more fair and configurable quota system later on. 

## Installing

TODO

## Configuring

TODO



