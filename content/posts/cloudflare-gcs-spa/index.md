---
title: "Hosting SPA with Cloudflare and GCS"
description: "How to host a single page application using only cloudflare and google cloud storage"
summary: "Wow this really is an amazing blog"
date: 2022-01-01T12:00:00+00:00
draft: true
---

Single page applications or SPA's need a webserver to make sure any request hitting the server is routed back to the single `index.html` file so that the application can controll the routing of the request. This can be acheived quite simply with nginx by doing something like this: (TODO: metion about shebang routing which is controlled by the client entirely and not routed to the server)

```nginx
server {
    server_name example.com;
    listen 80;
    root /usr/www/domain;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Now thats all well and good, however if you have users all the way around the world that user needs to connect to the origin each time because the routing logic of the application is done by nginx itself. That can lead to increased latency for your users connecting to the site depending on where the origin is. And its 2022 we can do better than this.

Now there are many services out there today which allow you to host SPA applications quite easily. You can also use [Cloudflare Pages][cloudflare pages] or an assortment of other managed soloutions which i would recommend picking if you can, however its not always possible. A lot of these services only allow you to connect a git repository and will only deploy artifacts from their build system. What if i just want to provide the built files directly? As for now its not possible without doing it yourself using s3/gcs.

Lots more detail can be found on the [React deployment documentation][react deployment docs]

## Soloution

Cloudflare added something called Transform Rules which basically allows us to acheive what our nginx config was doing but being executed at the edge.

Under the `When incoming requests match…` click `edit expresssion` and enter the following (make sure to change `example.com` to the hostname where your hosting the SPA):

<!-- this doesnt work on my personal cloudflare account.. only on cloudflare enterprise???????? -->
```
(http.host eq "example.com" and not http.request.uri.path matches "\.(?:css|js|jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$")
```

Then you want to rewrite to a static path of `/index.html`. It should look like this:
![Cloudflare transform rule example](cloudflare-transform-rule.png)

<!-- Page Links -->
[cloudflare pages]: https://pages.cloudflare.com/ "Cloudflare Pages"
[react deployment docs]: https://create-react-app.dev/docs/deployment/ "React deployment docs"
