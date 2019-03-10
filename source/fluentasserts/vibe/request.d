module fluentasserts.vibe.request;

version(Have_vibe_d_http):

import vibe.inet.url;
import vibe.http.router;
import vibe.http.form;
import vibe.data.json;

import vibe.stream.memory;

import std.conv, std.string, std.array;
import std.algorithm, std.conv;
import std.stdio;
import std.exception;

import fluentasserts.core.base;
import fluentasserts.core.results;

//@safe:

RequestRouter request(URLRouter router)
{
  return new RequestRouter(router);
}

///
final class RequestRouter {
  private {
    alias ExpectedCallback = void delegate(Response res);
    ExpectedCallback[] expected;
    URLRouter router;
    HTTPServerRequest preparedRequest;

    string[string] headers;

    string responseBody;
    string requestBody;
  }

  ///
  this(URLRouter router) {
    this.router = router;
  }

  /// Send a string[string] to the server as x-www-form-urlencoded data
  RequestRouter send(string[string] data) {
    auto dst = appender!string;

    dst.writeFormData(data);
    header("Content-Type", "application/x-www-form-urlencoded");

    return send(dst.data);
  }

  /// Send data to the server. You can send strings, Json or any other object
  /// which will be serialized to Json
  RequestRouter send(T)(T data) {
    static if (is(T == string))
    {
      requestBody = data;
      return this;
    }
    else static if (is(T == Json))
    {
      requestBody = data.toPrettyString;
      () @trusted { preparedRequest.bodyReader = createMemoryStream(cast(ubyte[]) requestBody); }();
      preparedRequest.json = data;
      return this;
    }
    else
    {
      return send(data.serializeToJson());
    }
  }

  /// Add a header to the server request
  RequestRouter header(string name, string value) {
    if(preparedRequest is null) {
      headers[name] = value;
    } else {
      preparedRequest.headers[name] = value;
    }
    return this;
  }

  /// Send a POST request
  RequestRouter post(string host = "localhost", ushort port = 80)(string path) {
    return customMethod!(HTTPMethod.POST, host, port)(path);
  }

  /// Send a PATCH request
  RequestRouter patch(string host = "localhost", ushort port = 80)(string path) {
    return customMethod!(HTTPMethod.PATCH, host, port)(path);
  }

  /// Send a PUT request
  RequestRouter put(string host = "localhost", ushort port = 80)(string path) {
    return customMethod!(HTTPMethod.PUT, host, port)(path);
  }

  /// Send a DELETE request
  RequestRouter delete_(string host = "localhost", ushort port = 80)(string path) {
    return customMethod!(HTTPMethod.DELETE, host, port)(path);
  }

  /// Send a GET request
  RequestRouter get(string host = "localhost", ushort port = 80)(string path) {
    return customMethod!(HTTPMethod.GET, host, port)(path);
  }

  /// Send a custom method request
  RequestRouter customMethod(HTTPMethod method, string host = "localhost", ushort port = 80)(string path) {
    return customMethod!method(URL("http://" ~ host ~ ":" ~ port.to!string ~ path));
  }

  /// ditto
  RequestRouter customMethod(HTTPMethod method)(URL url) {
    preparedRequest = createTestHTTPServerRequest(url, method);
    preparedRequest.host = url.host;

    foreach(name, value; headers) {
      preparedRequest.headers[name] = value;
    }

    return this;
  }

  RequestRouter expectHeaderExist(string name, const string file = __FILE__, const size_t line = __LINE__) {
    void localExpectHeaderExist(Response res) {
      auto result = res.headers.keys.should.contain(name, file, line);
      result.message = new MessageResult("Response header `" ~ name ~ "` is missing.");
    }

    expected ~= &localExpectHeaderExist;

    return this;
  }

  RequestRouter expectHeader(string name, string value, const string file = __FILE__, const size_t line = __LINE__) {
    expectHeaderExist(name, file, line);

    void localExpectedHeader(Response res) {
      auto result = res.headers[name].should.equal(value, file, line);
      result.message = new MessageResult("Response header `" ~ name ~ "` has an unexpected value. Expected `"
        ~ value ~ "` != `" ~ res.headers[name].to!string ~ "`");
    }

    expected ~= &localExpectedHeader;

    return this;
  }

  RequestRouter expectHeaderContains(string name, string value, const string file = __FILE__, const size_t line = __LINE__) {
    expectHeaderExist(name, file, line);

    void expectHeaderContains(Response res) {
      auto result = res.headers[name].should.contain(value, file, line);
      result.message = new MessageResult("Response header `" ~ name ~ "` has an unexpected value. Expected `"
        ~ value ~ "` not found in `" ~ res.headers[name].to!string ~ "`");
    }

    expected ~= &expectHeaderContains;

    return this;
  }

  RequestRouter expectStatusCode(int code, const string file = __FILE__, const size_t line = __LINE__) {
    void localExpectStatusCode(Response res) {
      if(code != 404 && res.statusCode == 404) {
        writeln("\n\nIs your route defined here?");
        router.getAllRoutes.map!(a => a.method.to!string ~ " " ~ a.pattern).each!writeln;
      }

      if(code != res.statusCode) {
        IResult[] results = [ cast(IResult) new MessageResult("Invalid status code."),
                              cast(IResult) new ExpectedActualResult(code.to!string ~ " - " ~ httpStatusText(code),
                                                                     res.statusCode.to!string ~ " - " ~ httpStatusText(res.statusCode)),
                              cast(IResult) new SourceResult(file, line) ];

        throw new TestException(results, file, line);
      }
    }

    expected ~= &localExpectStatusCode;

    return this;
  }

  private void performExpected(Response res) {
    foreach(func; expected) {
      func(res);
    }
  }

  void end() {
    end((Response response) => { });
  }

  void end(T)(T callback) @trusted {
    import vibe.stream.operations : readAllUTF8;
    import vibe.inet.webform;
    import vibe.stream.memory;

    auto data = new ubyte[5000];

    static if(__traits(compiles, createMemoryStream(data) )) {
      MemoryStream stream = createMemoryStream(data);
    } else {
      MemoryStream stream = new MemoryStream(data);
    }

    HTTPServerResponse res = createTestHTTPServerResponse(stream);
    res.statusCode = 404;

    static if(__traits(compiles, createMemoryStream(data) )) {
      preparedRequest.bodyReader = createMemoryStream(cast(ubyte[]) requestBody);
    } else {
      preparedRequest.bodyReader = new MemoryStream(cast(ubyte[]) requestBody);
    }

    router.handleRequest(preparedRequest, res);

    if(res.bytesWritten == 0 && data[0] == 0) {
      enum notFound = "HTTP/1.1 404 No Content\r\n\r\n";
      data = cast(ubyte[]) notFound;
    }

    auto response = new Response(data, res.bytesWritten);

    callback(response)();

    performExpected(response);
  }
}

///
class Response {
  ubyte[] bodyRaw;

  private {
    Json _bodyJson;
    string responseLine;
    string originalStringData;
  }

  ///
  string[string] headers;

  ///
  int statusCode;

  /// Instantiate the Response
  this(ubyte[] data, ulong len) {
    this.originalStringData = (cast(char[])data).toStringz.to!string.dup;

    auto bodyIndex = originalStringData.indexOf("\r\n\r\n");

    assert(bodyIndex != -1, "Invalid response data: \n" ~ originalStringData ~ "\n\n");

    auto headers = originalStringData[0 .. bodyIndex].split("\r\n").array;

    responseLine = headers[0];
    statusCode = headers[0].split(" ")[1].to!int;

    foreach (i; 1 .. headers.length) {
      auto header = headers[i].split(": ");
      this.headers[header[0]] = header[1];
    }

    bodyRaw = data[bodyIndex + 4 .. bodyIndex + 4 + len];
  }

  /// get the body as a string
  string bodyString() {
    return (cast(char[])bodyRaw).toStringz.to!string.dup;
  }

  /// get the body as a json object
  Json bodyJson() {
    if (_bodyJson.type == Json.Type.undefined)
    {
      string str = this.bodyString();

      try {
        _bodyJson = str.parseJson;
      } catch(Exception e) {
        writeln("`" ~ str ~ "` is not a json string");
      }
    }

    return _bodyJson;
  }

  /// get the request as a string
  override string toString() const {
    return originalStringData;
  }
}

@("Mocking a GET Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.get("*", &sayHello);
  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .post("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Mocking a POST Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.post("*", &sayHello);
  request(router)
    .post("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Mocking a PATCH Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.patch("*", &sayHello);
  request(router)
    .patch("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Mocking a PUT Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.put("*", &sayHello);
  request(router)
    .put("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Mocking a DELETE Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.delete_("*", &sayHello);
  request(router)
    .delete_("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Mocking a ACL Request")
unittest {
  auto router = new URLRouter();

  void sayHello(HTTPServerRequest, HTTPServerResponse res)
  {
    res.writeBody("hello");
  }

  router.match(HTTPMethod.ACL, "*", &sayHello);

  request(router)
    .customMethod!(HTTPMethod.ACL)("/")
      .end((Response response) => {
        response.bodyString.should.equal("hello");
      });

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyString.should.not.equal("hello");
      });
}

@("Sending headers")
unittest {
  auto router = new URLRouter();

  void checkHeaders(HTTPServerRequest req, HTTPServerResponse)
  {
    req.headers["Accept"].should.equal("application/json");
  }

  router.any("*", &checkHeaders);

  request(router)
    .get("/")
    .header("Accept", "application/json")
      .end();
}

@("Sending raw string")
unittest {
  import std.string;

  auto router = new URLRouter();

  void checkStringData(HTTPServerRequest req, HTTPServerResponse)
  {
    req.bodyReader.peek.assumeUTF.to!string.should.equal("raw string");
  }

  router.any("*", &checkStringData);

  request(router)
    .post("/")
        .send("raw string")
      .end();
}

@("Receiving raw binary")
unittest {
  import std.string;

  auto router = new URLRouter();

  void checkStringData(HTTPServerRequest req, HTTPServerResponse res)
  {
    res.writeBody(cast(ubyte[]) [0, 1, 2], 200, "application/binary");
  }

  router.any("*", &checkStringData);

  request(router)
    .post("/")
    .end((Response response) => {
      response.bodyRaw.should.equal(cast(ubyte[]) [0,1,2]);
    });
}

@("Sending form data")
unittest {
  auto router = new URLRouter();

  void checkFormData(HTTPServerRequest req, HTTPServerResponse)
  {
    req.headers["content-type"].should.equal("application/x-www-form-urlencoded");

    req.form["key1"].should.equal("value1");
    req.form["key2"].should.equal("value2");
  }

  router.any("*", &checkFormData);

  request(router)
    .post("/")
    .send(["key1": "value1", "key2": "value2"])
      .end();
}

@("Sending json data")
unittest {
  auto router = new URLRouter();

  void checkJsonData(HTTPServerRequest req, HTTPServerResponse)
  {
    req.json["key"].to!string.should.equal("value");
  }

  router.any("*", &checkJsonData);

  request(router)
    .post("/")
        .send(`{ "key": "value" }`.parseJsonString)
      .end();
}

@("Receive json data")
unittest {
  auto router = new URLRouter();

  void respondJsonData(HTTPServerRequest, HTTPServerResponse res)
  {
    res.writeJsonBody(`{ "key": "value"}`.parseJsonString);
  }

  router.any("*", &respondJsonData);

  request(router)
    .get("/")
      .end((Response response) => {
        response.bodyJson["key"].to!string.should.equal("value");
      });
}

@("Expect status code")
unittest {
  auto router = new URLRouter();

  void respondStatus(HTTPServerRequest, HTTPServerResponse res)
  {
    res.statusCode = 200;
    res.writeBody("");
  }

  router.get("*", &respondStatus);

  request(router)
    .get("/")
    .expectStatusCode(200)
      .end();


  ({
    request(router)
      .post("/")
      .expectStatusCode(200)
        .end();
  }).should.throwException!TestException.msg.should.startWith("Invalid status code.");
}


@("Expect header")
unittest {
  auto router = new URLRouter();

  void respondHeader(HTTPServerRequest, HTTPServerResponse res)
  {
    res.headers["some-header"] = "some-value";
    res.writeBody("");
  }

  router.get("*", &respondHeader);


  // Check for the exact header value:
  request(router)
    .get("/")
    .expectHeader("some-header", "some-value")
      .end();


  ({
    request(router)
      .post("/")
      .expectHeader("some-header", "some-value")
        .end();
  }).should.throwAnyException.msg.should.startWith("Response header `some-header` is missing.");

  ({
    request(router)
      .get("/")
      .expectHeader("some-header", "other-value")
        .end();
  }).should.throwAnyException.msg.should.startWith("Response header `some-header` has an unexpected value");

  // Check if a header exists
  request(router)
    .get("/")
    .expectHeaderExist("some-header")
      .end();


  ({
    request(router)
      .post("/")
      .expectHeaderExist("some-header")
        .end();
  }).should.throwAnyException.msg.should.startWith("Response header `some-header` is missing.");

  // Check if a header contains a string
  request(router)
    .get("/")
    .expectHeaderContains("some-header", "value")
      .end();

  ({
    request(router)
      .get("/")
      .expectHeaderContains("some-header", "other")
        .end();
  }).should.throwAnyException.msg.should.contain("Response header `some-header` has an unexpected value.");
}
