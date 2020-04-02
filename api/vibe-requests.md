# Vibe.d Requests API

[up](../README.md)

Mocking HTTP requests are usefull for api tests. This module allows you to mock requests for a [vibe.d](https://vibed.org/) router.

## Setup

1. Include the vibe assert package package: `fluent-asserts-vibe`
2. Import the module: `import fluentasserts.vibe.request` or `import fluent.asserts`

## Summary

- [Mocking GET requests](#mocking-get-requests)
- [Other requests](#other-requests)
- [Sending headers](#sending-headers)
- [Sending string data](#sending-string-data)
- [Sending form data](#sending-form-data)
- [Sending JSON data](#sending-json-data)
- [Receive JSON data](#receive-json-data)
- [Expect status code](#expect-status-code)
- [Expect header value](#expect-header-value)

## Examples

### Mocking GET requests

Returns an array containg the keys of an Json object.

Given a simple router
```D
	auto router = new URLRouter();

	void sayHello(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.writeBody("hello");
	}

	router.any("*", &sayHello);
```

You can mock requests like this:
```D
	request(router)
		.get("/")
			.end((Response response) => {
				response.bodyString.should.equal("hello");
			});
```

The above example creates a `GET` requests and sends it to the router. The handler response is sent as a
callback to the `end` callback, where you can add your custom asserts.

### Other requests

You can also mock `POST`, `PATCH`, `PUT`, `DELETE` requests by using the folowing methods:

```D
	RequestRouter post(string path);
	RequestRouter patch(string path);
	RequestRouter put(string path);
	RequestRouter delete_(string path);
```

Or if you want to pass a different (HTTP method)[https://vibed.org/api/vibe.http.common/HTTPMethod] you can use the generic request methods:
```D
	customMethod(HTTPMethod method)(string path);
	customMethod(HTTPMethod method)(URL url);
```

### Sending headers

```D
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
```

### Sending string data

```D
	import std.string;

	auto router = new URLRouter();

	void checkStringData(HTTPServerRequest req, HTTPServerResponse)
	{
		req.bodyReader.peek.assumeUTF.should.equal("raw string");
	}

	router.any("*", &checkStringData);
```

```D
	request(router)
		.post("/")
		.send("raw string")
			.end();
```


### Sending form data

```D
	auto router = new URLRouter();

	void checkFormData(HTTPServerRequest req, HTTPServerResponse)
	{
		req.headers["content-type"].should.equal("application/x-www-form-urlencoded");
		req.form["key1"].should.equal("value1");
		req.form["key2"].should.equal("val2ue2");
	}

	router.any("*", &checkFormData);
```

```D
	request(router)
		.post("/")
		.send(["key1": "value1", "key2": "value2"])
			.end();
```

### Sending JSON data

```D
	auto router = new URLRouter();

	void checkJsonData(HTTPServerRequest req, HTTPServerResponse)
	{
		req.json["key"].to!string.should.equal("value");
	}

	router.any("*", &checkJsonData);
```

```D
	request(router)
		.post("/")
		.send(`{ "key": "value" }`.parseJsonString)
			.end();
```


### Receive JSON data

```D
	auto router = new URLRouter();

	void respondJsonData(HTTPServerRequest, HTTPServerResponse res)
	{
		res.writeJsonBody(`{ "key": "value"}`.parseJsonString);
	}

	router.any("*", &respondJsonData);
```

```D
	request(router)
		.get("/")
			.end((Response response) => {
				response.bodyJson["key"].to!string.should.equal("value");
			});
```

### Expect status code

```D
	auto router = new URLRouter();

	void respondStatus(HTTPServerRequest, HTTPServerResponse res)
	{
		res.statusCode = 200;
		res.writeBody("");
	}

	router.get("*", &respondStatus);
```

```D
	request(router)
		.get("/")
		.expectStatusCode(200)
			.end();


	should.throwAnyException({
		request(router)
			.post("/")
			.expectStatusCode(200)
				.end();
	}).msg.should.equal("Expected status code `200` not found. Got `404` instead");
```


### Expect header value

```D
	auto router = new URLRouter();

	void respondHeader(HTTPServerRequest, HTTPServerResponse res)
	{
		res.headers["some-header"] = "some-value";
		res.writeBody("");
	}

	router.get("*", &respondHeader);
```

Check for the exact header value:
```D
	request(router)
		.get("/")
		.expectHeader("some-header", "some-value")
			.end();

	should.throwAnyException({
		request(router)
			.get("/")
			.expectHeader("some-header", "other-value")
				.end();
	}).msg.should.contain("Response header `some-header` has an unexpected value");

	should.throwAnyException({
		request(router)
			.post("/")
			.expectHeader("some-header", "some-value")
				.end();
	}).msg.should.equal("Response header `some-header` is missing.");
```

Check if a header exists

```D
	request(router)
		.get("/")
		.expectHeaderExist("some-header")
			.end();


	should.throwAnyException({
		request(router)
			.post("/")
			.expectHeaderExist("some-header")
				.end();
	}).msg.should.equal("Response header `some-header` is missing.");
```

Check if a header contains a string
```D
	request(router)
		.get("/")
		.expectHeaderContains("some-header", "value")
			.end();


	should.throwAnyException({
		request(router)
			.get("/")
			.expectHeaderContains("some-header", "other")
				.end();
	}).msg.should.contain("Response header `some-header` has an unexpected value.");
```
