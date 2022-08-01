# kmxgit 0.4

[kmxgit](https://git.kmx.io/kmx.io/kmxgit) is a web interface and a Git
server written in C and Elixir / Phoenix.

kmxgit started as a frontend for
[git-auth](https://git.kmx.io/kmx.io/git-auth).
Now public repositories are also supported.

This branch is work in progress, for the stable branch see
[v0.3](https://git.kmx.io/kmx.io/kmxgit/_tree/v0.3).

For releases see the tags, latest is
[v0.3.2](https://git.kmx.io/kmx.io/kmxgit/_tag/v0.3.2).

[ChangeLog](#ChangeLog) | [TODO](#todo)


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


<h1><a id="todo" href="#todo">TODO</a></h1>

## kmxgit 0.4

 - Performance improvements :
   - git bindings
     - free
     - segfault
   - DONE pygmentize -> prismjs
   - DONE shell commands -> elixir (mkdir mv rm)
   - DONE slugs without joins
   - disk usage
     - DONE disabled port
     - remove
 - DONE Display dotfiles
 - DONE Markdown
   - DONE refactor calls to module
   - DONE display "Markdown syntax enabled" in edit pages
 - Shared deploy SSH keys.
   - For now deploy keys must be unique (cannot be shared between repos).
 - Releases
   - infos
   - static files
 - Pull requests
   - Comments in diff
 - Issues / tickets
   - fields
     - trac: reported_by, owner, priority, milestone, component, version, severity, keywords, carbon_copy, branch
     - github: 
     - gitlab: 
   - discussion
   - status change
 - Static site generator
 - OAuth2
   - Google
   - Github
   - Gitlab


<h1><a id="ChangeLog" href="#ChangeLog">ChangeLog</a></h1>

<h2><a id="v0.3" href="#v0.3">Added in kmxgit 0.3</a></h2>

 - Disk usage
   - Per repo
   - Per user
   - Per organisation
   - Server-wise
 - Footer
   - environment variable
 - Fonts : Inter & Courier New
 - Dark navbar
 - Users
   - Profile picture
   - Link user in git log and commits
 - SEO
   - /_sitemap.txt
   - /robots.txt
 - Display markdown files as HTML
 - Bug : fix empty diff between commits and master
 - Optimizations
   - useless git commands (`git_put_log1`)
   - disk usage calculation
 - Front page
   - Stats
     - count users, organisations, repositories
     - disk usage
   - git cli help
     - git clone
     - git remote add kmx git@git.kmx.io:user/repo.git
     - git push -u kmx branch
     - git pull
     - install git
 - Admin
   - logo
   - Dashboard
     - Stats
   - disk usage (repos, orgs, users)
   - pipeline queries
   - sort by column
   - search
   - pagination (50 per page)
   - link to livedashboard
 - Hide private repos from public index
 - Less hr


<h2><a id="v0.2" href="#v0.2">Added in kmxgit 0.2</a></h2>

 - auth
   - auth users using `phx.gen.auth`
   - change password in separate form
   - session timeout (60 days)
   - auth with login
   - 2FA TOTP (Google Authenticator)
 - public repositories
   - option "public access ?"
   - routes
   - permissions
   - git-http-backend
 - front
   - source code coloration
   - line numbers
 - admin
   - create organisation without members
 - Git features
   - diff
     - sub-route, controller, view
     - links
     - line numbers
   - log
   - tags
 - notification e-mails
   - change login
   - change e-mail
   - change password
   - change 2FA

<h2><a id="v0.1" href="#v0.1">Added in kmxgit 0.1</a></h2>

 - git-auth
   - /_etc/git/auth.conf
   - /_etc/ssh/authorized_keys
   - bin/update_etc_git_auth
   - bin/update_git_ssh_authorized_keys
 - repository
   - in subdirectory
   - navigation
     - branches
   - tags
   - readme.md
 - same url slug for organisations and users
 - user auth using Guardian


<h1><a href="#copyright" id="copyright">Copyright</a></h1>

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
