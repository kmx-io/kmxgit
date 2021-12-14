# kmxgit

[kmxgit](https://git.kmx.io/kmx.io/kmxgit) is a Git server written in C
and Elixir.

## Installation

### git-auth installation

Please see [git-auth README.md](https://git.kmx.io/kmx.io/git-auth).


### Phoenix installation

 * Clone repo with `git clone https://git.kmx.io/kmx.io/kmxgit.git`
 * Change directory with `cd kmxgit`
 * Install dependencies with `mix deps.get`
 * Create and migrate your database with `mix ecto.setup`
 * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

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
