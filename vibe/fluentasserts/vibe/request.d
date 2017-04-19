module fluentasserts.vibe.request;

import vibe.inet.url;
import vibe.http.router;
import vibe.http.form;
import vibe.data.json;

import vibe.stream.memory;

import std.conv, std.string, std.array;
import std.algorithm, std.conv;
import std.stdio;
import std.exception;

import fluentasserts.core.string;

RequestRouter request(URLRouter router)
{
	return new RequestRouter(router);
}

final class RequestRouter
{
	private
	{
		alias ExpectedCallback = void delegate(Response res);
		ExpectedCallback[] expected;
		URLRouter router;
		HTTPServerRequest preparedRequest;

		string[string] headers;

		string responseBody;
	}

	this(URLRouter router)
	{
		this.router = router;
	}


	RequestRouter send(string[string] data) {
		auto dst = appender!string;

		dst.writeFormData(data);
		header("content-type", "application/x-www-form-urlencoded");

		return send(dst.data);
	}

	RequestRouter send(T)(T data)
	{
		static if (is(T == string))
		{
			preparedRequest.bodyReader = new MemoryStream(cast(ubyte[]) data);
			return this;
		}
		else static if (is(T == Json))
		{
			preparedRequest.json = data;
			return send(data.to!string);
		}
		else
		{
			return send(data.serializeToJson());
		}
	}

	RequestRouter header(string name, string value)
	{
		if(preparedRequest is null) {
			headers[name] = value;
		} else {
			preparedRequest.headers[name] = value;
		}
		return this;
	}

	RequestRouter post(string path)
	{
		return customMethod!(HTTPMethod.POST)(URL("http://localhost" ~ path));
	}

	RequestRouter patch(string path)
	{
		return customMethod!(HTTPMethod.PATCH)(URL("http://localhost" ~ path));
	}

	RequestRouter put(string path)
	{
		return customMethod!(HTTPMethod.PUT)(URL("http://localhost" ~ path));
	}

	RequestRouter delete_(string path)
	{
		return customMethod!(HTTPMethod.DELETE)(URL("http://localhost" ~ path));
	}

	RequestRouter get(string path)
	{
		return customMethod!(HTTPMethod.GET)(URL("http://localhost" ~ path));
	}

	RequestRouter customMethod(HTTPMethod method)(string path)
	{
		return customMethod!method(URL("http://localhost" ~ path));
	}

	RequestRouter customMethod(HTTPMethod method)(URL url)
	{
		preparedRequest = createTestHTTPServerRequest(url, method);
		preparedRequest.host = "localhost";

		foreach(name, value; headers) {
			preparedRequest.headers[name] = value;
		}

		return this;
	}

	RequestRouter expectHeaderExist(string name, const string file = __FILE__, const size_t line = __LINE__)
	{
		void localExpectHeaderExist(Response res) {
			enforce(name in res.headers, "Response header `" ~ name ~ "` is missing.", file, line);
		}

		expected ~= &localExpectHeaderExist;

		return this;
	}

	RequestRouter expectHeader(string name, string value, const string file = __FILE__, const size_t line = __LINE__)
	{
		expectHeaderExist(name, file, line);

		void localExpectedHeader(Response res) {
			enforce(res.headers[name] == value,
				"Response header `" ~ name ~ "` has an unexpected value. Expected `"
				~ value ~ "` != `" ~ res.headers[name].to!string ~ "`", file, line);
		}

		expected ~= &localExpectedHeader;

		return this;
	}

	RequestRouter expectHeaderContains(string name, string value, const string file = __FILE__, const size_t line = __LINE__)
	{
		expectHeaderExist(name, file, line);

		void expectHeaderContains(Response res) {
			enforce(res.headers[name].indexOf(value) != -1,
				"Response header `" ~ name ~ "` has an unexpected value. Expected `"
				~ value ~ "` not found in `" ~ res.headers[name].to!string ~ "`", file, line);
		}

		expected ~= &expectHeaderContains;

		return this;
	}

	RequestRouter expectStatusCode(int code, const string file = __FILE__, const size_t line = __LINE__)
	{
		void localExpectStatusCode(Response res) {
			if(code != 404 && res.statusCode == 404) {
				writeln("\n\nIs your route defined here?");
				router.getAllRoutes.map!(a => a.method.to!string ~ " " ~ a.pattern).each!writeln;
			}

			enforce(code == res.statusCode,
					"Expected status code `" ~ code.to!string
					~ "` not found. Got `" ~ res.statusCode.to!string ~ "` instead", file, line);
		}

		expected ~= &localExpectStatusCode;


		return this;
	}

	private void performExpected(Response res)
	{
		foreach(func; expected) {
			func(res);
		}
	}

	void end() {
		end((Response response) => { });
	}

	void end(T)(T callback)
	{
		import vibe.stream.operations : readAllUTF8;
		import vibe.inet.webform;

		auto data = new ubyte[5000];

		MemoryStream stream = new MemoryStream(data);
		HTTPServerResponse res = createTestHTTPServerResponse(stream);
		res.statusCode = 404;

		auto ptype = "Content-Type" in preparedRequest.headers;

		if (ptype) {
			parseFormData(preparedRequest.form, preparedRequest.files, *ptype, preparedRequest.bodyReader, 5000);
		}

		parseURLEncodedForm(preparedRequest.queryString, preparedRequest.query);

		router.handleRequest(preparedRequest, res);

		string responseString = (cast(string) data).toStringz.to!string;
		checkResponse(responseString);

		auto response = new Response(responseString);

		callback(response)();

		performExpected(response);
	}

	void checkResponse(ref string data) {
		if(data.length > 0) {
			return;
		}

		data = "HTTP/1.1 404 No Content\r\n\r\n";
	}
}

class Response
{
	string bodyString;

	private
	{
		Json _bodyJson;
		string responseLine;
		string data;
	}

	string[string] headers;
	int statusCode;

	this(string data)
	{
		this.data = data;

		auto bodyIndex = data.indexOf("\r\n\r\n");

		assert(bodyIndex != -1, "Invalid response data: \n" ~ data ~ "\n\n");

		auto headers = data[0 .. bodyIndex].split("\r\n").array;

		responseLine = headers[0];
		statusCode = headers[0].split(" ")[1].to!int;

		foreach (i; 1 .. headers.length)
		{
			auto header = headers[i].split(": ");
			this.headers[header[0]] = header[1];
		}

		bodyString = data[bodyIndex + 4 .. $];
	}

	@property Json bodyJson()
	{
		if (_bodyJson.type == Json.Type.undefined)
		{
			try {
				_bodyJson = bodyString.parseJson;
			} catch(Exception e) {
				writeln("`" ~ bodyString ~ "` is not a json string");
			}
		}

		return _bodyJson;
	}

	override
	string toString() {
		return data;
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
		req.bodyReader.peek.assumeUTF.should.equal("raw string");
	}

	router.any("*", &checkStringData);

	request(router)
		.post("/")
        .send("raw string")
			.end();
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
	}).should.throwAnyException.msg.should.equal("Expected status code `200` not found. Got `404` instead");
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
	}).should.throwAnyException.msg.should.equal("Response header `some-header` is missing.");

	({
		request(router)
			.get("/")
			.expectHeader("some-header", "other-value")
				.end();
	}).should.throwAnyException.msg.should.contain("Response header `some-header` has an unexpected value");

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
	}).should.throwAnyException.msg.should.equal("Response header `some-header` is missing.");

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
