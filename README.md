# HTTP Mock Server [![Gem Version](https://badge.fury.io/rb/http-mock-server.svg)](https://badge.fury.io/rb/http-mock-server)

A Ruby HTTP Mock Server based on Sinatra. JSON responses.

Features:
- simple config YAML file
- routes reloaded every time (but only the updated ones)
- string interpolations on response body (even *binding.pry* to inspect a request)

## Usage

- Install the gem: `gem install http-mock-server`
- Create a *mock.yml* config file in the current directory (see the [example](mock.yml))
- Execute: `http-mock-server`

## Options

Only one option: the config yaml file to use

Example: `http-mock-server conf.yml`

## Config example

```yml
config:
  namespace: '/api/v1'  # prepend to every route
  # no_cors: true       # don't send CORS headers
  port: 8080            # server port
  # timeout: 10         # response timeout
  verbose: true         # shows request params
not_found:
  body:
    message: This is not the path you are looking for...
routes:
  -
    get: '/posts'
    headers:
      'A-Random-Header': Something
    body:
      message: List of posts
  -
    get: '/posts/:id'
    body:
      content: A random number {rand} !
      extra:
        today: Today is {DateTime.now}
        request: Post id {params[:id]} - request path {request.path}
        more:
          is_first: "conditional check {params[:id] == '1' ? 'first' : 'other'}"
        an_array:
          - me
          - myself
          - I
        an_array2:
          -
            name: me
            age: 20
          -
            name: myself
            age: 30
          -
            name: I
            age: 40
  -
    get: '/pry'
    body:
      message: '{binding.pry}'
  -
    post: '/posts'
    status: 201
    body:
      code: 201
      result: Ok
  -
    delete: '*'
    status: 405
    body:
      message: Please don't do it
  -
    options: '*'
    status: 200
    headers:
      'Access-Control-Allow-Origin': '*'
      'Access-Control-Allow-Methods': 'HEAD,GET,PUT,DELETE,OPTIONS'
      'Access-Control-Allow-Headers': 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
      'Access-Control-Expose-Headers': 'X-Total-Count'
```

See [docs](http://sinatrarb.com/intro.html) for Sinatra request variables.

## Notes

- Routes are loaded from the Yaml config at each request, but it updates only the exiting routes; new / old routes are ignored, you have to restart *http-mock-server* to include them

## Do you like it? Star it!

If you use this component just star it. A developer is more motivated to improve a project when there is some interest.

## Contributors

- [Mattia Roccoberton](http://blocknot.es) - creator, maintainer

## License

[MIT](LICENSE.txt)
