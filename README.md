# DojoDrops

Experimental work in progress.

The goal is to make an easy tool for participants of our local coderdojo to serve small websites straight from dropbox.

Participants will be able to register a shared folder by it's url. The content of that folder will be served under a rootpath which is specified during the registration.

DojoDrops will load the content of smaller files (html, css, js) in memory and keep it in sync with dropbox. Requests for larger files will be redirected to a direct download url.