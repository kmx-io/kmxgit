# kmxgit

[kmxgit](https://git.kmx.io/kmx.io/kmxgit) is a web interface and a Git
server written in C and Elixir / Phoenix.

kmxgit started as a frontend for
[git-auth](https://git.kmx.io/kmx.io/git-auth).

Now public repositories are also supported.


## Installation

### git-auth installation

git-auth handles all permissions for a single git user accessible
through SSH with just one config file (`/etc/git/auth.conf`).

Please see [git-auth README.md](https://git.kmx.io/kmx.io/git-auth).


### Phoenix installation

 * Clone repo with `git clone https://git.kmx.io/kmx.io/kmxgit.git`
 * Change directory with `cd kmxgit`
 * Install dependencies with `mix deps.get`
 * Create and migrate your database with `mix ecto.setup`
 * Install `bin/*` into `/usr/local/bin`
 * Start Phoenix endpoint with `mix phx.server` or inside IEx with
   `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


### Public access

To setup public access repositories on HTTP or HTTPS you need to setup
your web server to serve certain requests with
[git-http-backend](https://git-scm.com/docs/git-http-backend).


#### Nginx setup

First you need to setup
[fcgiwrap](https://www.nginx.com/resources/wiki/start/topics/examples/fcgiwrap/) to serve on `127.0.0.1:9001`.

Then in your nginx server config :
```
location ~ ^(.*/info/refs|.*/git-upload-pack)$ {
    fastcgi_pass  127.0.0.1:9001;
    include       fastcgi_params;
    fastcgi_param SCRIPT_FILENAME  /usr/local/libexec/git/git-http-backend;
    fastcgi_param GIT_PROJECT_ROOT ~git;
    fastcgi_param PATH_INFO        $1;        
}
```


# TODO

## kmxgit v0.2

 - DONE auth
   - DONE auth users using `phx.gen.auth`
   - DONE change password in separate form
   - DONE session timeout (60 days)
   - DONE auth with login
   - DONE 2FA TOTP (Google Authenticator)
 - DONE public repositories
   - DONE option "public access ?"
   - DONE routes
   - DONE permissions
   - DONE git-http-backend
 - DONE front
   - DONE source code coloration
   - DONE line numbers
 - DONE admin
   - DONE create organisation without members
 - DONE Git features
   - DONE diff
     - DONE sub-route, controller, view
     - DONE links
     - DONE line numbers
   - DONE log
   - DONE tags
 - notification e-mails
   - DONE change login
   - DONE change e-mail
   - DONE change password
   - change 2FA


## kmxgit v0.3

 - OAuth2
   - Google
   - Github
   - Gitlab ?
 - Releases (tags with db info)


# Copyright

kmxgit - git server administration

Copyright 2021,2022 Thomas de Grivel <thoxdg@gmail.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
